// firestore_services.dart - COMPLETE VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  // =========================
  // MENU (compatible fields)
  // =========================
  Future<void> addMenu({
    required String nama, // old name
    required int harga, // old name
    required int stok,
    String? imageUrl,
    String? kategori, // old (kategori) used for tipe
    // optional new names also allowed as params (alias)
    String? namaMenu,
    int? hargaMenu,
    String? tipeMenu,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');

    // normalize: decide values (prefer explicit new aliases if provided)
    final _namaMenu = namaMenu ?? nama;
    final _hargaMenu = hargaMenu ?? harga;
    final _tipeMenu = tipeMenu ?? kategori ?? 'Umum';

    final docData = <String, dynamic>{
      // keep old names for backward compatibility
      'nama': nama,
      'harga': harga,
      'stok': stok,
      'gambarUrl': imageUrl ?? '',
      'kategori': kategori ?? _tipeMenu,
      'available': true,
      'createdAt': FieldValue.serverTimestamp(),

      // also write new normalized names
      'namaMenu': _namaMenu,
      'hargaMenu': _hargaMenu,
      'tipeMenu': _tipeMenu,
    };

    await _userRef(uid).collection('menu').add(docData);
  }

  Future<List<Map<String, dynamic>>> getMenu() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');

    final snapshot =
        await _userRef(
          uid,
        ).collection('menu').orderBy('createdAt', descending: true).get();

    // return raw doc map (will contain both old & new names if present)
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> deleteMenu(String menuId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');
    await _userRef(uid).collection('menu').doc(menuId).delete();
  }

  Future<void> updateMenu({
    required String menuId,
    String? nama,
    int? harga,
    String? kategori,
    String? namaMenu,
    int? hargaMenu,
    String? tipeMenu,
    String? imageUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');

    final Map<String, dynamic> updateData = {};
    // update both old and new keys if provided
    if (nama != null) updateData['nama'] = nama;
    if (harga != null) updateData['harga'] = harga;
    if (kategori != null) updateData['kategori'] = kategori;
    if (imageUrl != null) updateData['gambarUrl'] = imageUrl;

    if (namaMenu != null) updateData['namaMenu'] = namaMenu;
    if (hargaMenu != null) updateData['hargaMenu'] = hargaMenu;
    if (tipeMenu != null) updateData['tipeMenu'] = tipeMenu;

    if (updateData.isNotEmpty) {
      await _userRef(uid).collection('menu').doc(menuId).update(updateData);
    }
  }

  // =========================
  // CATATAN BELANJA (compatible)
  // =========================
  Future<void> addBelanja({
    // old names
    String? item,
    String? tipeBelanja,
    int? jumlah,
    int? total,
    String? keterangan,
    DateTime? tanggal,
    // new aliases
    String? keteranganBelanja,
    String? tipeBelanjaNew,
    int? jumlahBelanja,
    int? totalBelanja,
    DateTime? tanggalBelanja,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');

    final _item = item ?? '';
    final _tipe = tipeBelanjaNew ?? tipeBelanja ?? 'bahan';
    final _jumlah = jumlahBelanja ?? jumlah ?? 0;
    final _total = totalBelanja ?? total ?? 0;
    final _keterangan = keteranganBelanja ?? keterangan ?? '';
    final _tanggal = tanggalBelanja ?? tanggal ?? DateTime.now();

    final data = <String, dynamic>{
      // old fields
      'item': _item,
      'tipeBelanja': _tipe,
      'jumlah': _jumlah,
      'total': _total,
      'keterangan': _keterangan,
      'tanggal': Timestamp.fromDate(_tanggal),
      'createdAt': FieldValue.serverTimestamp(),
      // new alias fields
      'jumlahBelanja': _jumlah,
      'totalBelanja': _total,
      'keteranganBelanja': _keterangan,
      'tanggalBelanja': Timestamp.fromDate(_tanggal),
    };

    await _userRef(uid).collection('catatan_belanja').add(data);
  }

  Future<List<Map<String, dynamic>>> getBelanja() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');

    final snapshot =
        await _userRef(uid)
            .collection('catatan_belanja')
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> deleteBelanja(String belanjaId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');
    await _userRef(uid).collection('catatan_belanja').doc(belanjaId).delete();
  }

  // =========================
  // STREAM MENU USER
  // =========================
  Stream<List<Map<String, dynamic>>> getUserMenuStream() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

    return _userRef(uid)
        .collection('menu')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  // =========================
  // PESANAN (FIXED VERSION - menggunakan waktuPemesanan)
  // =========================
  Future<void> addPesanan({
    required String namaPemesan,
    required List<Map<String, dynamic>> menuList,
    required int totalHarga,
    required String tipePembayaran,
    required String status,
    required String orderId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');

    final now = DateTime.now();
    final data = <String, dynamic>{
      'namaPemesan': namaPemesan,
      'menu': menuList,
      'totalHarga': totalHarga,
      'tipePembayaran': tipePembayaran,
      'status': status,
      'waktuPemesanan': Timestamp.fromDate(now), // 🔥 UTAMAKAN field ini
      'createdAt': FieldValue.serverTimestamp(), // 🔥 backup field
      'orderId': orderId,
    };

    await _userRef(uid).collection('pesanan').add(data);
  }

  // 🔥 PERBAIKAN UTAMA: Method getPesananStream yang sudah diperbaiki
  Stream<QuerySnapshot> getPesananStream({
    String? statusFilter,
    String? waktuFilter,
  }) {
    final uid = currentUserId;
    if (uid == null) {
      print('❌ [FirestoreService] User not logged in');
      return const Stream.empty();
    }

    // 🔥 GUNAKAN waktuPemesanan untuk sorting
    Query query = _userRef(
      uid,
    ).collection('pesanan').orderBy('waktuPemesanan', descending: true);

    // 🔥 PERBAIKAN: Filter status - hanya jika bukan 'Semua Status'
    if (statusFilter != null && statusFilter != 'Semua Status') {
      print('🔍 [FirestoreService] Filtering by status: "$statusFilter"');
      query = query.where('status', isEqualTo: statusFilter);
    }

    // 🔥 PERBAIKAN: Filter waktu - gunakan waktuPemesanan
    if (waktuFilter != null && waktuFilter != 'Semua Waktu') {
      final now = DateTime.now();
      DateTime startDate;

      if (waktuFilter == 'Hari Ini') {
        startDate = DateTime(now.year, now.month, now.day);
        print('📅 [FirestoreService] Filter waktu: Hari Ini -> $startDate');
      } else if (waktuFilter == 'Minggu Ini') {
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        print('📅 [FirestoreService] Filter waktu: Minggu Ini -> $startDate');
      } else if (waktuFilter == 'Bulan Ini') {
        startDate = DateTime(now.year, now.month, 1);
        print('📅 [FirestoreService] Filter waktu: Bulan Ini -> $startDate');
      } else {
        startDate = DateTime(2000);
        print('📅 [FirestoreService] Filter waktu: Semua -> $startDate');
      }

      // 🔥 GUNAKAN waktuPemesanan untuk filtering
      query = query.where(
        'waktuPemesanan',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    print(
      '🎯 [FirestoreService] Final Query: status="$statusFilter", waktu="$waktuFilter"',
    );
    return query.snapshots();
  }

  Future<void> updatePesananStatus(String pesananId, String statusBaru) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');

    print('🔄 [FirestoreService] Updating status: $pesananId -> $statusBaru');
    await _userRef(
      uid,
    ).collection('pesanan').doc(pesananId).update({'status': statusBaru});
  }

  Future<void> deletePesanan(String pesananId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');
    await _userRef(uid).collection('pesanan').doc(pesananId).delete();
  }

  Future<List<Map<String, dynamic>>> searchPesananByPelanggan(
    String keyword,
  ) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');
    final snapshot =
        await _userRef(uid)
            .collection('pesanan')
            .where('namaPemesan', isGreaterThanOrEqualTo: keyword)
            .where('namaPemesan', isLessThanOrEqualTo: '$keyword\uf8ff')
            .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // =========================
  // TRANSAKSI
  // =========================
  Future<void> addTransaksi({
    required int total,
    required String metode,
    required String pesananId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');
    await _userRef(uid).collection('transaksi').add({
      'total': total,
      'metode': metode,
      'pesananId': pesananId,
      'tanggal': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getTransaksi() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');
    final snapshot =
        await _userRef(
          uid,
        ).collection('transaksi').orderBy('tanggal', descending: true).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // =========================
  // CATATAN UMUM
  // =========================
  Future<void> addCatatanUmum({
    required List<String> daftarPesananIds,
    required int totalHargaAllPesanan,
    required DateTime waktu,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');
    await _userRef(uid).collection('catatan_umum').add({
      'daftarPesanan': daftarPesananIds,
      'totalHargaAllPesanan': totalHargaAllPesanan,
      'detailWaktu': Timestamp.fromDate(waktu),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getCatatanUmum() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User belum login');
    final snapshot =
        await _userRef(uid)
            .collection('catatan_umum')
            .orderBy('createdAt', descending: true)
            .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // =========================
  // USER PROFILE
  // =========================
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final doc = await _userRef(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> updateLastLogin() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _userRef(uid).update({'lastLogin': FieldValue.serverTimestamp()});
  }

  // =========================
  // STORE SETTINGS (NEW - for profile page)
  // =========================

  /// Get store settings from Firestore
  Future<Map<String, dynamic>?> getStoreSettings() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final doc = await _firestore.collection('store_settings').doc(uid).get();

      if (doc.exists) {
        return doc.data();
      }
      // Return default values if no settings exist
      return {
        'storeName': 'KasirPro Store',
        'storeAddress': '',
        'storePhone': '',
        'receiptFooter': 'Terima kasih telah berbelanja',
        'createdAt': Timestamp.now(),
      };
    } catch (e) {
      print('Error getting store settings: $e');
      return null;
    }
  }

  /// Update store settings in Firestore
  Future<void> updateStoreSettings({
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? receiptFooter,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (storeName != null) updateData['storeName'] = storeName;
      if (storeAddress != null) updateData['storeAddress'] = storeAddress;
      if (storePhone != null) updateData['storePhone'] = storePhone;
      if (receiptFooter != null) updateData['receiptFooter'] = receiptFooter;

      await _firestore
          .collection('store_settings')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      print('Error updating store settings: $e');
      rethrow;
    }
  }

  /// Get user QRIS data from Firestore
  Future<Map<String, dynamic>?> getUserQrisData() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data();
        return {
          'qrisImageUrl': data?['qrisImageUrl'],
          'qrisBankName': data?['qrisBankName'],
          'qrisAccountName': data?['qrisAccountName'],
          'qrisUpdatedAt': data?['qrisUpdatedAt'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting user QRIS data: $e');
      return null;
    }
  }

  /// Update user QRIS data in Firestore
  Future<void> updateUserQrisData({
    required String qrisImageUrl,
    String? qrisBankName,
    String? qrisAccountName,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final updateData = <String, dynamic>{
        'qrisImageUrl': qrisImageUrl,
        'qrisUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (qrisBankName != null) updateData['qrisBankName'] = qrisBankName;
      if (qrisAccountName != null)
        updateData['qrisAccountName'] = qrisAccountName;

      await _firestore
          .collection('users')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user QRIS data: $e');
      rethrow;
    }
  }

  /// Clear user QRIS data
  Future<void> clearUserQrisData() async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'qrisImageUrl': FieldValue.delete(),
        'qrisBankName': FieldValue.delete(),
        'qrisAccountName': FieldValue.delete(),
        'qrisUpdatedAt': FieldValue.delete(),
      });
    } catch (e) {
      print('Error clearing user QRIS data: $e');
      rethrow;
    }
  }

  /// Update user profile information
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await _firestore
          .collection('users')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Get daily sales report
  Future<List<Map<String, dynamic>>> getDailySalesReport(DateTime date) async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('pesanan')
              .where(
                'waktuPemesanan',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('waktuPemesanan', isLessThan: Timestamp.fromDate(endOfDay))
              .where('status', isEqualTo: 'Sudah dibayar')
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'orderId': data['orderId'] ?? '',
          'namaPemesan': data['namaPemesan'] ?? '',
          'totalHarga': data['totalHarga'] ?? 0,
          'tipePembayaran': data['tipePembayaran'] ?? '',
          'waktuPemesanan': (data['waktuPemesanan'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting daily sales report: $e');
      return [];
    }
  }

  /// Get monthly statistics
  Future<Map<String, dynamic>> getMonthlyStatistics(int year, int month) async {
    final uid = currentUserId;
    if (uid == null) return {};

    try {
      final startDate = DateTime(year, month, 1);
      final endDate =
          month < 12 ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);

      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('pesanan')
              .where(
                'waktuPemesanan',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where('waktuPemesanan', isLessThan: Timestamp.fromDate(endDate))
              .where('status', isEqualTo: 'Sudah dibayar')
              .get();

      int totalOrders = 0;
      int totalRevenue = 0;
      Map<String, int> paymentMethodStats = {};
      Map<String, int> dailyStats = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalOrders++;
        totalRevenue += (data['totalHarga'] as int? ?? 0);

        // Payment method statistics
        final paymentMethod = data['tipePembayaran'] ?? 'Unknown';
        paymentMethodStats[paymentMethod] =
            (paymentMethodStats[paymentMethod] ?? 0) + 1;

        // Daily statistics
        final orderDate = (data['waktuPemesanan'] as Timestamp).toDate();
        final dateKey = '${orderDate.day}/${orderDate.month}';
        dailyStats[dateKey] = (dailyStats[dateKey] ?? 0) + 1;
      }

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'paymentMethodStats': paymentMethodStats,
        'dailyStats': dailyStats,
        'averageOrderValue': totalOrders > 0 ? totalRevenue ~/ totalOrders : 0,
      };
    } catch (e) {
      print('Error getting monthly statistics: $e');
      return {};
    }
  }

  /// Export data as CSV/JSON (placeholder - bisa diimplementasi sesuai kebutuhan)
  Future<String> exportDataAsJson(DateTime fromDate, DateTime toDate) async {
    // Ini adalah placeholder untuk fitur export
    // Implementasi real bisa mengexport ke file atau Google Drive
    return 'Export feature coming soon';
  }

  /// Get total sales for today
  Future<int> getTodaySales() async {
    final uid = currentUserId;
    if (uid == null) return 0;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('pesanan')
              .where(
                'waktuPemesanan',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('waktuPemesanan', isLessThan: Timestamp.fromDate(endOfDay))
              .where('status', isEqualTo: 'Sudah dibayar')
              .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['totalHarga'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      print('Error getting today sales: $e');
      return 0;
    }
  }

  /// Get total pending orders
  Future<int> getPendingOrdersCount() async {
    final uid = currentUserId;
    if (uid == null) return 0;

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('pesanan')
              .where(
                'status',
                whereIn: ['Menunggu Pembayaran', 'Belum dibayar'],
              )
              .get();

      return snapshot.size;
    } catch (e) {
      print('Error getting pending orders count: $e');
      return 0;
    }
  }

  /// Get total completed orders
  Future<int> getCompletedOrdersCount() async {
    final uid = currentUserId;
    if (uid == null) return 0;

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('pesanan')
              .where('status', isEqualTo: 'Sudah dibayar')
              .get();

      return snapshot.size;
    } catch (e) {
      print('Error getting completed orders count: $e');
      return 0;
    }
  }

  /// Get top selling items
  Future<List<Map<String, dynamic>>> getTopSellingItems({int limit = 5}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('pesanan')
              .where('status', isEqualTo: 'Sudah dibayar')
              .get();

      final Map<String, int> itemCounts = {};
      final Map<String, String> itemNames = {};

      for (var order in snapshot.docs) {
        final data = order.data();
        final menuList = data['menu'] as List<dynamic>? ?? [];

        for (var item in menuList) {
          final itemMap = item as Map<String, dynamic>;
          final itemId = itemMap['nama']?.toString() ?? '';
          final itemName = itemMap['nama']?.toString() ?? '';
          final quantity = (itemMap['jumlah'] as int? ?? 0);

          if (itemId.isNotEmpty) {
            itemCounts[itemId] = (itemCounts[itemId] ?? 0) + quantity;
            itemNames[itemId] = itemName;
          }
        }
      }

      // Sort by quantity sold (descending)
      final sortedItems =
          itemCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sortedItems.take(limit).map((entry) {
        return {
          'itemName': itemNames[entry.key] ?? entry.key,
          'quantitySold': entry.value,
        };
      }).toList();
    } catch (e) {
      print('Error getting top selling items: $e');
      return [];
    }
  }
}
