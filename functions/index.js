const functions = require("firebase-functions");
const admin = require("firebase-admin");
try {
  admin.initializeApp();
} catch (e) {}

// Trigger saat ada Time Record baru (misal: Bangun Pagi)
exports.sendNotificationOnTimeRecord = functions.firestore
  .document("time_records/{recordId}")
  .onCreate(async (snap, context) => {
    const record = snap.data();
    const userId = record.user_id;

    // Ambil data siswa
    const userQuery = await admin
      .firestore()
      .collection("users")
      .where("id", "==", userId)
      .limit(1)
      .get();

    if (userQuery.empty) return null;
    const student = userQuery.docs[0].data();

    // Kirim ke Guru
    const guruQuery = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "guru")
      .get();

    const teacherTokens = [];
    guruQuery.forEach((doc) => {
      const data = doc.data();
      if (data.fcm_token) teacherTokens.push(data.fcm_token);
    });

    // Kirim ke Ortu
    const ortuQuery = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "ortu")
      .get();

    const parentTokens = [];
    ortuQuery.forEach((doc) => {
      const data = doc.data();
      if (data.fcm_token) parentTokens.push(data.fcm_token);
    });

    const allTokens = [...teacherTokens, ...parentTokens];
    if (allTokens.length === 0) return null;

    const payload = {
      notification: {
        title: "Aktivitas Siswa",
        body: `${student.username} baru saja mencatat: ${record.record_type}`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "activity_update",
      },
    };

    return admin.messaging().sendToDevice(allTokens, payload);
  });

// Trigger saat ada Activity baru (misal: Sholat, Makan)
exports.sendNotificationOnActivity = functions.firestore
  .document("activities/{activityId}")
  .onCreate(async (snap, context) => {
    const activity = snap.data();
    const userId = activity.user_id;

    const userQuery = await admin
      .firestore()
      .collection("users")
      .where("id", "==", userId)
      .limit(1)
      .get();

    if (userQuery.empty) return null;
    const student = userQuery.docs[0].data();

    // Kirim ke Guru
    const guruQuery = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "guru")
      .get();

    const teacherTokens = [];
    guruQuery.forEach((doc) => {
      const data = doc.data();
      if (data.fcm_token) teacherTokens.push(data.fcm_token);
    });

    // Kirim ke Ortu
    const ortuQuery = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "ortu")
      .get();

    const parentTokens = [];
    ortuQuery.forEach((doc) => {
      const data = doc.data();
      if (data.fcm_token) parentTokens.push(data.fcm_token);
    });

     const allTokens = [...teacherTokens, ...parentTokens];
    if (allTokens.length === 0) return null;

    const payload = {
      notification: {
        title: "Aktivitas Siswa",
        body: `${student.username} baru saja mencatat: ${activity.activity_type}`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "activity_update",
      },
    };

    return admin.messaging().sendToDevice(allTokens, payload);
  });
