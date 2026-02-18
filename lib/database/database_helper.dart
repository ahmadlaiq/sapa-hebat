import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DatabaseHelper._init();

  // Helper to simulate 'database' getter for initialization if needed
  // In Firestore, we just use the instance.
  Future<void> initialize() async {
    await _seedData();
  }

  Future<void> _seedData() async {
    print('🌱 Starting database seeding...');

    // Step 1: FORCE DELETE all existing data
    print('🗑️ Deleting old data...');
    try {
      // Delete all users
      final usersSnapshot = await _firestore.collection('users').get();
      for (var doc in usersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all activities
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .get();
      for (var doc in activitiesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all time_records
      final timeSnapshot = await _firestore.collection('time_records').get();
      for (var doc in timeSnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Old data deleted');
    } catch (e) {
      print('⚠️ Error deleting old data: $e');
    }

    // Step 2: Create Users
    print('👥 Creating users...');
    final usersRef = _firestore.collection('users');

    // Create 2 Guru
    for (int i = 1; i <= 2; i++) {
      await usersRef.add({
        'id': 100 + i,
        'username': 'guru$i',
        'password': '123456',
        'role': 'guru',
      });
    }
    print('✅ Created 2 gurus (guru1: 101, guru2: 102)');

    // Create 5 Ortu
    for (int i = 1; i <= 5; i++) {
      await usersRef.add({
        'id': 200 + i,
        'username': 'ortu$i',
        'password': '123456',
        'role': 'ortu',
      });
    }
    print('✅ Created 5 parents (ortu1-5: 201-205)');

    // Create 10 Siswa with relationships
    for (int i = 1; i <= 10; i++) {
      int guruId = (i <= 5) ? 101 : 102;
      int ortuId = 200 + ((i - 1) ~/ 2) + 1;

      await usersRef.add({
        'id': 300 + i,
        'username': 'siswa$i',
        'password': '123456',
        'role': 'siswa',
        'guru_id': guruId,
        'ortu_id': ortuId,
      });
    }
    print('✅ Created 10 students (siswa1-10: 301-310)');
    print('   - Guru1 manages: siswa1-5');
    print('   - Guru2 manages: siswa6-10');
    print('   - Ortu1: siswa1-2, Ortu2: siswa3-4, etc.');

    // Step 3: Create Sample Activities for ALL students
    print('📝 Creating sample activities...');
    final activitiesRef = _firestore.collection('activities');
    final timeRecordsRef = _firestore.collection('time_records');

    final today = DateTime.now().toIso8601String().substring(0, 10);

    for (int i = 1; i <= 10; i++) {
      int studentId = 300 + i;

      // Time Record 1: Bangun Pagi
      await timeRecordsRef.add({
        'id': DateTime.now().millisecondsSinceEpoch + i * 1000,
        'user_id': studentId,
        'record_type': 'bangun_pagi',
        'time_value': '05:30',
        'created_at': '${today}T05:30:00.000Z',
        'status_guru': 'pending',
        'status_ortu': 'pending',
      });

      // Activity 1: Beribadah
      await activitiesRef.add({
        'id': DateTime.now().millisecondsSinceEpoch + i * 1001,
        'user_id': studentId,
        'activity_type': 'beribadah',
        'category': 'Islam',
        'items': '["Sholat Subuh","Sholat Dzuhur","Sholat Ashar","Mengaji"]',
        'notes': 'Alhamdulillah lancar',
        'created_at': '${today}T06:00:00.000Z',
        'status_guru': 'pending',
        'status_ortu': 'pending',
      });

      // Activity 2: Makan Sehat
      await activitiesRef.add({
        'id': DateTime.now().millisecondsSinceEpoch + i * 1002,
        'user_id': studentId,
        'activity_type': 'makan_sehat',
        'category': 'sayur',
        'items': '["Sayur Bayam","Telur","Tempe"]',
        'notes': 'Enak sekali',
        'created_at': '${today}T07:00:00.000Z',
        'status_guru': 'pending',
        'status_ortu': 'pending',
      });

      // Activity 3: Olahraga
      await activitiesRef.add({
        'id': DateTime.now().millisecondsSinceEpoch + i * 1003,
        'user_id': studentId,
        'activity_type': 'olahraga',
        'category': 'lari',
        'items': '[]',
        'notes': 'Lari pagi 30 menit',
        'created_at': '${today}T08:00:00.000Z',
        'status_guru': 'pending',
        'status_ortu': 'pending',
      });

      // Activity 4: Sekolah
      await activitiesRef.add({
        'id': DateTime.now().millisecondsSinceEpoch + i * 1004,
        'user_id': studentId,
        'activity_type': 'sekolah',
        'category': 'hadir',
        'items': '["Matematika","Bahasa Indonesia","IPA"]',
        'notes': 'Semua pelajaran seru',
        'created_at': '${today}T13:00:00.000Z',
        'status_guru': 'pending',
        'status_ortu': 'pending',
      });

      // Activity 5: Gemar Belajar
      await activitiesRef.add({
        'id': DateTime.now().millisecondsSinceEpoch + i * 1005,
        'user_id': studentId,
        'activity_type': 'gemar_belajar',
        'category': 'pr',
        'items': '["PR Matematika","Membaca Buku"]',
        'notes': 'Belajar 2 jam',
        'created_at': '${today}T15:00:00.000Z',
        'status_guru': 'pending',
        'status_ortu': 'pending',
      });

      // Activity 6: Bermasyarakat
      await activitiesRef.add({
        'id': DateTime.now().millisecondsSinceEpoch + i * 1006,
        'user_id': studentId,
        'activity_type': 'bermasyarakat',
        'category': 'gotong_royong',
        'items': '[]',
        'notes': 'Kerja bakti di kampung',
        'created_at': '${today}T16:00:00.000Z',
        'status_guru': 'pending',
        'status_ortu': 'pending',
      });

      // Time Record 2: Tidur Cepat
      await timeRecordsRef.add({
        'id': DateTime.now().millisecondsSinceEpoch + i * 1007,
        'user_id': studentId,
        'record_type': 'tidur_cepat',
        'time_value': '21:00',
        'created_at': '${today}T21:00:00.000Z',
        'status_guru': 'pending',
        'status_ortu': 'pending',
      });
    }

    print('✅ Created 80 activities (8 activities × 10 students)');
    print('✅ All activities set to PENDING status');
    print('');
    print('🎉 Database seeding completed!');
    print('');
    print('📋 Summary:');
    print('   - 2 Gurus: guru1 (101), guru2 (102)');
    print('   - 5 Parents: ortu1-5 (201-205)');
    print('   - 10 Students: siswa1-10 (301-310)');
    print('   - 80 Activities: All pending verification');
    print('');
    print('🔐 Login Info:');
    print('   Guru: guru1/123456 or guru2/123456');
    print('   Ortu: ortu1/123456 to ortu5/123456');
    print('   Siswa: siswa1/123456 to siswa10/123456');
  }

  // CRUD Methods

  Future<int> insertUser(Map<String, dynamic> user) async {
    try {
      // Generate ID using timestamp if not provided (simulating AUTOINCREMENT)
      final int newId = DateTime.now().millisecondsSinceEpoch;
      final userData = Map<String, dynamic>.from(user);
      userData['id'] = newId;

      await _firestore.collection('users').add(userData);
      return newId;
    } catch (e) {
      if (kDebugMode) print('Error inserting user: $e');
      return -1;
    }
  }

  Future<Map<String, dynamic>?> getUser(
    String username,
    String password,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final user = snapshot.docs.first.data();

        // Update FCM Token on login
        String? token = await NotificationService().getToken();
        if (token != null) {
          await snapshot.docs.first.reference.update({'fcm_token': token});
        }

        return user;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting user: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int> insertActivity(Map<String, dynamic> activity) async {
    try {
      final int newId = DateTime.now().millisecondsSinceEpoch;
      final activityData = Map<String, dynamic>.from(activity);
      activityData['id'] = newId;
      // Default statuses if not present (though usually handled by UI/logic)
      if (!activityData.containsKey('status_guru')) {
        activityData['status_guru'] = 'pending';
      }
      if (!activityData.containsKey('status_ortu')) {
        activityData['status_ortu'] = 'pending';
      }

      await _firestore.collection('activities').add(activityData);
      return newId;
    } catch (e) {
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getActivities(int userId) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('user_id', isEqualTo: userId)
          .get();

      final list = snapshot.docs.map((doc) => doc.data()).toList();
      list.sort(
        (a, b) => (b['created_at'] as String).compareTo(a['created_at']),
      );
      return list;
    } catch (e) {
      if (kDebugMode) print('Error getActivities: $e');
      return [];
    }
  }

  Future<int> insertTimeRecord(Map<String, dynamic> record) async {
    try {
      final int newId = DateTime.now().millisecondsSinceEpoch;
      final recordData = Map<String, dynamic>.from(record);
      recordData['id'] = newId;
      if (!recordData.containsKey('status_guru')) {
        recordData['status_guru'] = 'pending';
      }
      if (!recordData.containsKey('status_ortu')) {
        recordData['status_ortu'] = 'pending';
      }

      await _firestore.collection('time_records').add(recordData);
      return newId;
    } catch (e) {
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getTimeRecords(
    int userId,
    String type,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('time_records')
          .where('user_id', isEqualTo: userId)
          .where('record_type', isEqualTo: type)
          .get();

      final list = snapshot.docs.map((doc) => doc.data()).toList();
      list.sort(
        (a, b) => (b['created_at'] as String).compareTo(a['created_at']),
      );
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllTimeRecords(int userId) async {
    try {
      final snapshot = await _firestore
          .collection('time_records')
          .where('user_id', isEqualTo: userId)
          .get();

      final list = snapshot.docs.map((doc) => doc.data()).toList();
      list.sort(
        (a, b) => (b['created_at'] as String).compareTo(a['created_at']),
      );
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getTodayActivity(
    int userId,
    String activityType,
  ) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final snapshot = await _firestore
          .collection('activities')
          .where('user_id', isEqualTo: userId)
          .where('activity_type', isEqualTo: activityType)
          .get();

      // Client-side filtering for today
      for (var doc in snapshot.docs) {
        final createdAt = doc['created_at'] as String;
        if (createdAt.startsWith(today)) {
          return doc.data();
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getTodayActivity: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTodayTimeRecord(
    int userId,
    String recordType,
  ) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final snapshot = await _firestore
          .collection('time_records')
          .where('user_id', isEqualTo: userId)
          .where('record_type', isEqualTo: recordType)
          .get();

      // Client-side filtering for today
      for (var doc in snapshot.docs) {
        final createdAt = doc['created_at'] as String;
        if (createdAt.startsWith(today)) {
          return doc.data();
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getTodayTimeRecord: $e');
      return null;
    }
  }

  Future<int> upsertActivity(Map<String, dynamic> activity) async {
    try {
      final userId = activity['user_id'];
      final type = activity['activity_type'];
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final snapshot = await _firestore
          .collection('activities')
          .where('user_id', isEqualTo: userId)
          .where('activity_type', isEqualTo: type)
          .get();

      // Client-side find existing for today
      QueryDocumentSnapshot? existingDoc;
      for (var doc in snapshot.docs) {
        final createdAt = doc['created_at'] as String;
        if (createdAt.startsWith(today)) {
          existingDoc = doc;
          break;
        }
      }

      if (existingDoc != null) {
        // Update
        await existingDoc.reference.update(activity);
        return existingDoc['id'];
      } else {
        // Insert
        return await insertActivity(activity);
      }
    } catch (e) {
      if (kDebugMode) print('Upsert activity error: $e');
      return -1;
    }
  }

  Future<int> upsertTimeRecord(Map<String, dynamic> record) async {
    try {
      final userId = record['user_id'];
      final type = record['record_type'];
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final snapshot = await _firestore
          .collection('time_records')
          .where('user_id', isEqualTo: userId)
          .where('record_type', isEqualTo: type)
          .get();

      QueryDocumentSnapshot? existingDoc;
      for (var doc in snapshot.docs) {
        final createdAt = doc['created_at'] as String;
        if (createdAt.startsWith(today)) {
          existingDoc = doc;
          break;
        }
      }

      if (existingDoc != null) {
        await existingDoc.reference.update(record);
        return existingDoc['id'];
      } else {
        return await insertTimeRecord(record);
      }
    } catch (e) {
      return -1;
    }
  }

  // Get Students Relationship
  Future<List<Map<String, dynamic>>> getStudentsByGuru(int guruId) async {
    try {
      // Removing 'role' filter to avoid composite index requirement
      final snapshot = await _firestore
          .collection('users')
          .where('guru_id', isEqualTo: guruId)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsByOrtu(int ortuId) async {
    try {
      // Removing 'role' filter to avoid composite index requirement
      final snapshot = await _firestore
          .collection('users')
          .where('ortu_id', isEqualTo: ortuId)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> getDailyProgressCount(int userId) async {
    int count = 0;
    if ((await getTodayTimeRecord(userId, 'bangun_pagi')) != null) count++;
    if ((await getTodayActivity(userId, 'beribadah')) != null) count++;
    if ((await getTodayActivity(userId, 'makan_sehat')) != null) count++;
    if ((await getTodayActivity(userId, 'olahraga')) != null) count++;
    if ((await getTodayActivity(userId, 'sekolah')) != null) count++;
    if ((await getTodayActivity(userId, 'gemar_belajar')) != null) count++;
    if ((await getTodayActivity(userId, 'bermasyarakat')) != null) count++;
    if ((await getTodayTimeRecord(userId, 'tidur_cepat')) != null) count++;
    return count;
  }

  // Verification Methods

  // Updated to support filtering by list of student IDs
  Future<List<Map<String, dynamic>>> getPendingActivities(
    String role,
    List<int> studentIds,
  ) async {
    try {
      if (studentIds.isEmpty) return [];

      final statusCol = role == 'guru' ? 'status_guru' : 'status_ortu';

      // Removing status filter from query to avoid composite index requirement
      final snapshot = await _firestore
          .collection('activities')
          .where('user_id', whereIn: studentIds)
          .get();

      final list = snapshot.docs.map((doc) => doc.data()).toList();

      // Filter client-side
      final filteredList = list
          .where((data) => data[statusCol] == 'pending')
          .toList();

      // Sort client-side
      filteredList.sort(
        (a, b) => (b['created_at'] as String).compareTo(a['created_at']),
      );

      return filteredList;
    } catch (e) {
      if (kDebugMode) print('getPendingActivities error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPendingTimeRecords(
    String role,
    List<int> studentIds,
  ) async {
    try {
      if (studentIds.isEmpty) return [];
      final statusCol = role == 'guru' ? 'status_guru' : 'status_ortu';

      // Removing status filter from query to avoid composite index requirement
      final snapshot = await _firestore
          .collection('time_records')
          .where('user_id', whereIn: studentIds)
          .get();

      final list = snapshot.docs.map((doc) => doc.data()).toList();

      // Filter client-side
      final filteredList = list
          .where((data) => data[statusCol] == 'pending')
          .toList();

      // Sort client-side
      filteredList.sort(
        (a, b) => (b['created_at'] as String).compareTo(a['created_at']),
      );

      return filteredList;
    } catch (e) {
      return [];
    }
  }

  Future<int> updateActivityStatus(int id, String role, String status) async {
    try {
      final statusCol = role == 'guru' ? 'status_guru' : 'status_ortu';
      final snapshot = await _firestore
          .collection('activities')
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({statusCol: status});
        return 1;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> updateTimeRecordStatus(int id, String role, String status) async {
    try {
      final statusCol = role == 'guru' ? 'status_guru' : 'status_ortu';
      final snapshot = await _firestore
          .collection('time_records')
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({statusCol: status});
        return 1;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getAllActivitiesForMonitoring(
    String role,
    List<int> studentIds, // New param to filter monitoring
  ) async {
    try {
      if (studentIds.isEmpty) return [];

      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('user_id', whereIn: studentIds)
          .get();

      final timeSnapshot = await _firestore
          .collection('time_records')
          .where('user_id', whereIn: studentIds)
          .get();

      List<Map<String, dynamic>> combined = [];
      for (var doc in activitiesSnapshot.docs) {
        combined.add({...doc.data(), 'data_type': 'activity'});
      }
      for (var doc in timeSnapshot.docs) {
        combined.add({...doc.data(), 'data_type': 'time'});
      }

      combined.sort(
        (a, b) => (b['created_at'] as String).compareTo(a['created_at']),
      );
      return combined;
    } catch (e) {
      return [];
    }
  }

  Future<void> updateDailyStatus(
    int userId,
    String date,
    String role,
    String status,
  ) async {
    try {
      final statusCol = role == 'guru' ? 'status_guru' : 'status_ortu';

      // Update activities
      final actSnapshot = await _firestore
          .collection('activities')
          .where('user_id', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      bool batchHasOps = false;

      for (var doc in actSnapshot.docs) {
        final createdAt = doc['created_at'] as String;
        if (createdAt.startsWith(date)) {
          batch.update(doc.reference, {statusCol: status});
          batchHasOps = true;
        }
      }

      // Update time records
      final timeSnapshot = await _firestore
          .collection('time_records')
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doc in timeSnapshot.docs) {
        final createdAt = doc['created_at'] as String;
        if (createdAt.startsWith(date)) {
          batch.update(doc.reference, {statusCol: status});
          batchHasOps = true;
        }
      }

      if (batchHasOps) {
        await batch.commit();
      }
    } catch (e) {
      if (kDebugMode) print('Error updateDailyStatus: $e');
    }
  }

  // Verification Notes
  Future<int> upsertVerificationNote(
    int userId,
    String date,
    String role,
    String note,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('verification_notes')
          .where('user_id', isEqualTo: userId)
          .where('date', isEqualTo: date)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'note': note,
          'created_at': DateTime.now().toIso8601String(),
        });
        return snapshot.docs.first.data()['id'];
      } else {
        final int newId = DateTime.now().millisecondsSinceEpoch;
        await _firestore.collection('verification_notes').add({
          'id': newId,
          'user_id': userId,
          'date': date,
          'role': role,
          'note': note,
          'created_at': DateTime.now().toIso8601String(),
        });
        return newId;
      }
    } catch (e) {
      return -1;
    }
  }

  Future<String?> getVerificationNote(
    int userId,
    String date,
    String role,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('verification_notes')
          .where('user_id', isEqualTo: userId)
          .where('date', isEqualTo: date)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['note'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Formerly used to close DB, locally we can just do nothing or sign out auth
  Future close() async {
    // No explicit close needed for Firestore instance usually
  }
}
