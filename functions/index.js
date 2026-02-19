const functions = require("firebase-functions");
const admin = require("firebase-admin");
try {
  admin.initializeApp();
} catch (e) {}

// Helper: Cek kelengkapan & kirim notif jika baru saja SELESAI
// Target: 8 aktivitas harian harus lengkap
async function checkCompletionAndNotify(userId) {
  const now = new Date();
  // Set timeframe ke Hari Ini (WIB/Local Time server)
  // Karena server Cloud Functions biasanya UTC, kita perlu hati-hati.
  // Tapi data `created_at` di DB biasanya ISOString (UTC).
  // Kita set start/end day dalam UTC untuk mencakup 24 jam "hari ini" versi user.
  // Untuk simplifikasi, kita asumsikan user ada di WIB (UTC+7).
  // Offset WIB = +7 jam.

  // Kita pakai jam server (UTC) lalu sesuaikan ke tanggal user.
  // Tapi untuk amannya, kita query range -7 jam s/d +17 jam dari 'sekarang'?
  // LEBIH AMAN: Query berdasarkan string tanggal yyyy-mm-dd yang dikirim dari klien.
  // TAPI, function trigger tidak dapat info tanggal lokal user.
  // JADI: Kita query record yang dibuat dalam 24 jam terakhir? Tidak akurat.
  // SOLUSI: Query record dengan 'created_at' >= start of current day (UTC).
  // Jam 00:00 WIB = Jam 17:00 UTC kemarin.

  const wibOffset = 7 * 60 * 60 * 1000;
  const nowWIB = new Date(now.getTime() + wibOffset);
  const startOfDayWIB = new Date(nowWIB.setHours(0, 0, 0, 0));
  const endOfDayWIB = new Date(nowWIB.setHours(23, 59, 59, 999));

  // Kembalikan ke UTC untuk query Firestore
  const startQuery = new Date(
    startOfDayWIB.getTime() - wibOffset,
  ).toISOString();
  const endQuery = new Date(endOfDayWIB.getTime() - wibOffset).toISOString();

  console.log(
    `Checking completion for user ${userId} between ${startQuery} and ${endQuery}`,
  );

  // 1. Ambil Time Records hari ini
  const timeQuery = await admin
    .firestore()
    .collection("time_records")
    .where("user_id", "==", userId)
    .where("created_at", ">=", startQuery)
    .where("created_at", "<=", endQuery)
    .get();

  // 2. Ambil Activities hari ini
  const activityQuery = await admin
    .firestore()
    .collection("activities")
    .where("user_id", "==", userId)
    .where("created_at", ">=", startQuery)
    .where("created_at", "<=", endQuery)
    .get();

  // 3. Kumpulkan Tipe Aktivitas Unik
  const completedTypes = new Set();

  timeQuery.docs.forEach((doc) => {
    const data = doc.data();
    // Normalisasi tipe dari DB: 'bangun_pagi', 'tidur_cepat'
    if (data.record_type === "bangun_pagi") completedTypes.add("Bangun Pagi");
    if (data.record_type === "tidur_cepat") completedTypes.add("Tidur Cepat");
  });

  activityQuery.docs.forEach((doc) => {
    const data = doc.data();
    // Normalisasi tipe dari DB: 'beribadah', 'makan_sehat', 'olahraga', 'sekolah', 'gemar_belajar', 'bermasyarakat'
    // Kita capitalize atau sesuaikan stringnya
    // Asumsi di DB: snake_case
    const type = data.activity_type; // 'beribadah', etc.
    if (type) completedTypes.add(type);
  });

  // Total tipe unik aktivitas harian ada 8:
  // 1. bangun_pagi (time_records)
  // 2. tidur_cepat (time_records)
  // 3. beribadah
  // 4. makan_sehat
  // 5. olahraga
  // 6. sekolah
  // 7. gemar_belajar
  // 8. bermasyarakat

  // Namun, activity_type di DB mungkin berbeda format (misal 'makan_sehat' vs 'Makan Sehat').
  // Di DashboardSiswaScreen: 'Bangun Pagi', 'Beribadah', 'Makan Sehat', 'Olahraga', 'Sekolah', 'Gemar Belajar', 'Bermasyarakat', 'Tidur Cepat'.
  // Kita hitung jumlah set.

  // Mapping activity types to normalized keys to ensure distinct count
  const normalizedSet = new Set();
  completedTypes.forEach((t) => {
    let key = t.toLowerCase().replace(/ /g, "_");
    normalizedSet.add(key);
  });

  // Tipe yang diharapkan:
  // bangun_pagi, tidur_cepat, beribadah, makan_sehat, olahraga, sekolah, gemar_belajar, bermasyarakat
  // Total = 8.

  const currentCount = normalizedSet.size;
  console.log(
    `User ${userId} progress: ${currentCount}/8 items (${Array.from(normalizedSet)})`,
  );

  // 4. Cek Kelengkapan (Minimal 8)
  if (currentCount >= 8) {
    // Cek User Data untuk last_completed_notif_date
    const userQuery = await admin
      .firestore()
      .collection("users")
      .where("id", "==", userId)
      .limit(1)
      .get();

    if (userQuery.empty) return;
    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();
    const todayStr = startOfDayWIB.toISOString().split("T")[0]; // YYYY-MM-DD

    if (userData.last_completed_notif_date === todayStr) {
      console.log("Already notified today for user:", userId);
      return; // Sudah notif hari ini
    }

    // 5. Kirim Notif Konsolidasi
    console.log("🎉 COMPLETED! Sending daily report notification...");

    const tokens = [];

    // Ambil Token Guru
    if (userData.guru_id) {
      const guruQ = await admin
        .firestore()
        .collection("users")
        .where("id", "==", userData.guru_id)
        .limit(1)
        .get();
      if (!guruQ.empty && guruQ.docs[0].data().fcm_token)
        tokens.push(guruQ.docs[0].data().fcm_token);
    }

    // Ambil Token Ortu
    if (userData.ortu_id) {
      const ortuQ = await admin
        .firestore()
        .collection("users")
        .where("id", "==", userData.ortu_id)
        .limit(1)
        .get();
      if (!ortuQ.empty && ortuQ.docs[0].data().fcm_token)
        tokens.push(ortuQ.docs[0].data().fcm_token);
    }

    if (tokens.length > 0) {
      const message = {
        notification: {
          title: "Laporan Harian Selesai ✅",
          body: `Siswa ${userData.username} telah menyelesaikan semua aktivitas hari ini.`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "daily_complete",
          student_id: String(userId),
        },
        tokens: tokens,
      };

      try {
        const resp = await admin.messaging().sendEachForMulticast(message);
        console.log(
          "Sent completion notif to",
          tokens.length,
          "devices. Success:",
          resp.successCount,
        );

        // Update flag di user agar tidak spam
        await userDoc.ref.update({ last_completed_notif_date: todayStr });
      } catch (e) {
        console.error("Error sending completion notif:", e);
      }
    } else {
      console.log("Completed but no tokens found for Guru/Ortu.");
    }
  }
}

exports.sendNotificationOnTimeRecord = functions.firestore
  .document("time_records/{recordId}")
  .onCreate(async (snap, context) => {
    const record = snap.data();
    await checkCompletionAndNotify(record.user_id);
  });

exports.sendNotificationOnActivity = functions.firestore
  .document("activities/{activityId}")
  .onCreate(async (snap, context) => {
    const activity = snap.data();
    await checkCompletionAndNotify(activity.user_id);
  });

// ==========================================
// SCHEDULED FUNCTIONS (Memerlukan Blaze Plan)
// ==========================================

// 1. Peringatan Cepat Tidur (Siswa) - Jam 21:00 WIB
exports.remindSleep = functions.pubsub
  .schedule("0 21 * * *")
  .timeZone("Asia/Jakarta")
  .onRun(async (context) => {
    console.log("⏰ Running Sleep Reminder");

    // Kirim ke semua user dengan role 'siswa'
    // Note: Query all users bisa lambat jika user banyak.
    // Batch processing disarankan untuk prod.
    const snapshot = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "siswa")
      .get();

    const tokens = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      if (data.fcm_token) tokens.push(data.fcm_token);
    });

    if (tokens.length > 0) {
      // FCM max 500 tokens per batch.
      // Untuk demo/skala kecil, kita kirim sekaligus atau loop.
      // sendEachForMulticast support up to 500.

      const batches = [];
      while (tokens.length > 0) {
        batches.push(tokens.splice(0, 500));
      }

      for (const batchTokens of batches) {
        const message = {
          notification: {
            title: "Waktunya Tidur! 🌙",
            body: "Sudah malam nih, ayo tidur cepat biar besok segar!",
          },
          tokens: batchTokens,
        };
        await admin.messaging().sendEachForMulticast(message);
      }
      console.log("Sent sleep reminder to", snapshot.size, "students");
    }
  });

// 2. Peringatan Bangun Kesiangan (Siswa) - Jam 06:00 WIB
// Cek siapa yg belum input 'bangun_pagi' hari ini
exports.checkWakeUp = functions.pubsub
  .schedule("0 6 * * *")
  .timeZone("Asia/Jakarta")
  .onRun(async (context) => {
    console.log("⏰ Running Wake Up Check");

    // 1. Get all students
    const studentsSnap = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "siswa")
      .get();

    // 2. Define today's time range
    const now = new Date(); // Warning: Server time UTC? Function timezone setting applies to trigger time, but now() is system time.
    // Cloud Functions Gen 1 environment variable TZ usually needs explicit handling or datetime libraries.
    // But `now` object is created at execution time.
    // Let's rely on simple UTC logic assuming function runs at 6 AM WIB = 23 PM UTC (prev day).

    // Safer: Just take current server time and look back 6 hours?
    // Or just query created_at > (now - 6 hours).
    // Target: 'bangun_pagi' record created "today".

    // Strategi: Ambil semua siswa, lalu cek siapa yg TIDAK punya record bangun_pagi hari ini.
    // Ini agak berat (N+1 query).
    // Optimization: Ambil semua time_records hari ini tipe 'bangun_pagi', simpan user_id nya dalam Set.
    // Lalu bandingkan dengan list student.

    const wibOffset = 7 * 60 * 60 * 1000;
    const nowWIB = new Date(Date.now() + wibOffset);
    const startOfDayStr = new Date(
      nowWIB.setHours(0, 0, 0, 0) - wibOffset,
    ).toISOString();

    const recordsSnap = await admin
      .firestore()
      .collection("time_records")
      .where("record_type", "==", "bangun_pagi")
      .where("created_at", ">=", startOfDayStr)
      .get();

    const awakenedUserIds = new Set();
    recordsSnap.forEach((doc) => awakenedUserIds.add(doc.data().user_id));

    const lateTokens = [];
    studentsSnap.forEach((doc) => {
      const data = doc.data();
      if (!awakenedUserIds.has(data.id) && data.fcm_token) {
        lateTokens.push(data.fcm_token);
      }
    });

    if (lateTokens.length > 0) {
      // Kirim dalam batch 500
      const chunks = [];
      while (lateTokens.length > 0) chunks.push(lateTokens.splice(0, 500));

      for (const chunk of chunks) {
        const message = {
          notification: {
            title: "Belum Bangun? ☀️",
            body: "Jangan lupa catat bangun pagimu ya! Semangat pagi!",
          },
          tokens: chunk,
        };
        await admin.messaging().sendEachForMulticast(message);
      }
      console.log(
        "Sent wake up reminder to",
        recordsSnap.size,
        "wake vs",
        studentsSnap.size,
        "total students",
      );
    }
  });

// 3. Peringatan Harian Belum Ngisi (Siswa) - Jam 19:00 WIB & Lapor Ortu Jam 20:00
// Digabung logicnya mirip checkWakeUp tapi cek completion count.
exports.dailyReminder = functions.pubsub
  .schedule("0 19 * * *")
  .timeZone("Asia/Jakarta")
  .onRun(async (context) => {
    // Logic serupa: Cek siapa yg count < 8.
    // Kirim notif "Ayo lengkapi catatan harimu!"
    console.log("⏰ Daily Reminder Triggered");
    // (Simplified logic for now due to complexity of checking all activities)
    // Implementation pending user request detail.
  });
