const functions = require("firebase-functions");
const admin = require("firebase-admin");
try {
  admin.initializeApp();
} catch (e) {}

// Trigger saat ada Time Record baru (misal: Bangun Pagi)
exports.sendNotificationOnTimeRecord = functions.firestore
  .document("time_records/{recordId}")
  .onCreate(async (snap, context) => {
    console.log("🚀 Triggered sendNotificationOnTimeRecord");
    const record = snap.data();
    const userId = record.user_id;

    // Ambil data siswa
    const userQuery = await admin
      .firestore()
      .collection("users")
      .where("id", "==", userId)
      .limit(1)
      .get();

    if (userQuery.empty) {
      console.log("❌ Student not found for ID:", userId);
      return null;
    }
    const student = userQuery.docs[0].data();
    console.log("👤 Student found:", student.username);

    // Pastikan siswa memiliki guru_id dan ortu_id
    const guruId = student.guru_id;
    const ortuId = student.ortu_id;
    const tokens = [];

    // Ambil token Guru
    if (guruId) {
      const guruQuery = await admin
        .firestore()
        .collection("users")
        .where("id", "==", guruId)
        .limit(1)
        .get();

      if (!guruQuery.empty) {
        const guruData = guruQuery.docs[0].data();
        if (guruData.fcm_token) {
          console.log("✅ Found Guru Token for:", guruData.username);
          tokens.push(guruData.fcm_token);
        } else {
          console.log("⚠️ Guru found but no FCM token:", guruData.username);
        }
      }
    }

    // Ambil token Ortu
    if (ortuId) {
      const ortuQuery = await admin
        .firestore()
        .collection("users")
        .where("id", "==", ortuId)
        .limit(1)
        .get();

      if (!ortuQuery.empty) {
        const ortuData = ortuQuery.docs[0].data();
        if (ortuData.fcm_token) {
          console.log("✅ Found Ortu Token for:", ortuData.username);
          tokens.push(ortuData.fcm_token);
        } else {
          console.log("⚠️ Ortu found but no FCM token:", ortuData.username);
        }
      }
    }

    if (tokens.length === 0) {
      console.log("⚠️ No tokens found to send notification.");
      return null;
    }

    const message = {
      notification: {
        title: "Aktivitas Siswa",
        body: `${student.username} baru saja mencatat: ${record.record_type}`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "activity_update",
      },
      tokens: tokens, // Array of tokens
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(
        "📤 Notification sent successfully:",
        response.successCount + " messages sent",
      );
      if (response.failureCount > 0) {
        console.log("❌ Failed to send:", response.failureCount + " messages");
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Token: ${tokens[idx]} Error:`, resp.error);
          }
        });
      }
      return response;
    } catch (error) {
      console.error("❌ Error sending notification:", error);
      return null;
    }
  });

// Trigger saat ada Activity baru (misal: Sholat, Makan)
exports.sendNotificationOnActivity = functions.firestore
  .document("activities/{activityId}")
  .onCreate(async (snap, context) => {
    console.log("🚀 Triggered sendNotificationOnActivity");
    const activity = snap.data();
    const userId = activity.user_id;

    const userQuery = await admin
      .firestore()
      .collection("users")
      .where("id", "==", userId)
      .limit(1)
      .get();

    if (userQuery.empty) {
      console.log("❌ Student not found for ID:", userId);
      return null;
    }
    const student = userQuery.docs[0].data();
    console.log("👤 Student found:", student.username);

    // Pastikan siswa memiliki guru_id dan ortu_id
    const guruId = student.guru_id;
    const ortuId = student.ortu_id;
    const tokens = [];

    // Ambil token Guru
    if (guruId) {
      const guruQuery = await admin
        .firestore()
        .collection("users")
        .where("id", "==", guruId)
        .limit(1)
        .get();

      if (!guruQuery.empty) {
        const guruData = guruQuery.docs[0].data();
        if (guruData.fcm_token) {
          console.log("✅ Found Guru Token for:", guruData.username);
          tokens.push(guruData.fcm_token);
        } else {
          console.log("⚠️ Guru found but no FCM token:", guruData.username);
        }
      }
    }

    // Ambil token Ortu
    if (ortuId) {
      const ortuQuery = await admin
        .firestore()
        .collection("users")
        .where("id", "==", ortuId)
        .limit(1)
        .get();

      if (!ortuQuery.empty) {
        const ortuData = ortuQuery.docs[0].data();
        if (ortuData.fcm_token) {
          console.log("✅ Found Ortu Token for:", ortuData.username);
          tokens.push(ortuData.fcm_token);
        } else {
          console.log("⚠️ Ortu found but no FCM token:", ortuData.username);
        }
      }
    }

    if (tokens.length === 0) {
      console.log("⚠️ No tokens found to send notification.");
      return null;
    }

    const message = {
      notification: {
        title: "Aktivitas Siswa",
        body: `${student.username} baru saja mencatat: ${activity.activity_type}`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "activity_update",
      },
      tokens: tokens,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(
        "📤 Notification sent successfully:",
        response.successCount + " messages sent",
      );
      if (response.failureCount > 0) {
        console.log("❌ Failed to send:", response.failureCount + " messages");
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Token: ${tokens[idx]} Error:`, resp.error);
          }
        });
      }
      return response;
    } catch (error) {
      console.error("❌ Error sending notification:", error);
      return null;
    }
  });
