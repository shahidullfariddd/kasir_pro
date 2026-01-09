// dashboard_screen.dart - COMPLETE FIXED VERSION WITH HOURLY CHART
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pro/services/firestore_services.dart';
import 'package:kasir_pro/widgets/sidebar_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _selectedRange = "Minggu Ini";
  String formatRupiah(int value) => _currencyFormat.format(value);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime? _toDateTime(dynamic tsOrDt) {
    if (tsOrDt == null) return null;
    if (tsOrDt is Timestamp) return tsOrDt.toDate();
    if (tsOrDt is DateTime) return tsOrDt;
    if (tsOrDt is int) return DateTime.fromMillisecondsSinceEpoch(tsOrDt);
    return null;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      final digits = value.replaceAll(RegExp(r'[^0-9\-]'), '');
      return int.tryParse(digits) ?? 0;
    }
    return 0;
  }

  // ✅ Total Penjualan - SUDAH BERFUNGSI
  Future<int> _getTotalPenjualanByDate(DateTime date) async {
    try {
      final uid = _firestoreService.currentUserId;
      if (uid == null) return 0;

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('pesanan')
              .where(
                'waktuPemesanan',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('waktuPemesanan', isLessThan: Timestamp.fromDate(endOfDay))
              .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status == 'sudah dibayar') {
          total += _toInt(data['totalHarga']);
        }
      }
      return total;
    } catch (e) {
      print('❌ Error Total Penjualan: $e');
      return 0;
    }
  }

  Future<int> getTotalPenjualanHariIni() =>
      _getTotalPenjualanByDate(DateTime.now());
  Future<int> getTotalPenjualanKemarin() => _getTotalPenjualanByDate(
    DateTime.now().subtract(const Duration(days: 1)),
  );

  // ✅ Jumlah Pesanan - SUDAH BERFUNGSI
  Future<int> _getJumlahPesananByDate(DateTime date) async {
    try {
      final uid = _firestoreService.currentUserId;
      if (uid == null) return 0;

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('pesanan')
              .where(
                'waktuPemesanan',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('waktuPemesanan', isLessThan: Timestamp.fromDate(endOfDay))
              .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error Jumlah Pesanan: $e');
      return 0;
    }
  }

  Future<int> getJumlahPesananHariIni() =>
      _getJumlahPesananByDate(DateTime.now());
  Future<int> getJumlahPesananKemarin() =>
      _getJumlahPesananByDate(DateTime.now().subtract(const Duration(days: 1)));

  // 🔥 PERBAIKAN: Total Belanja - FIXED
  Future<int> _getTotalBelanjaByDate(DateTime date) async {
    try {
      final uid = _firestoreService.currentUserId;
      if (uid == null) return 0;

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('catatan_belanja')
              .where(
                'tanggal',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
              .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // 🔥 PERBAIKAN: Coba semua kemungkinan field
        final value =
            data['totalBelanja'] ?? data['total'] ?? data['jumlah'] ?? 0;
        total += _toInt(value);
      }
      print(
        '💰 Total Belanja $date: $total (${snapshot.docs.length} documents)',
      );
      return total;
    } catch (e) {
      print('❌ Error Total Belanja: $e');
      return 0;
    }
  }

  Future<int> getTotalBelanjaHariIni() =>
      _getTotalBelanjaByDate(DateTime.now());
  Future<int> getTotalBelanjaKemarin() =>
      _getTotalBelanjaByDate(DateTime.now().subtract(const Duration(days: 1)));

  // 🔥 PERBAIKAN UTAMA: Method untuk grafik dengan DEBUG EXTENSIVE
  Future<Map<DateTime, int>> getDataPenjualan(String range) async {
    try {
      final Map<DateTime, int> hasil = {};
      final now = DateTime.now();
      DateTime startDate;

      if (range == "Hari Ini") {
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ); // Mulai dari 00:00 hari ini
        print('📅 Range: Hari Ini -> $startDate');
      } else if (range == "Minggu Ini") {
        startDate = now.subtract(Duration(days: now.weekday - 1));
        print('📅 Range: Minggu Ini -> $startDate');
      } else {
        startDate = DateTime(now.year, now.month, 1);
        print('📅 Range: Bulan Ini -> $startDate');
      }

      final uid = _firestoreService.currentUserId;
      if (uid == null) {
        print('❌ User tidak login');
        return {};
      }

      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('pesanan')
              .where(
                'waktuPemesanan',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .get();

      print('📊 Data dari Firestore: ${snapshot.docs.length} documents');

      int processedCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dt = _toDateTime(data['waktuPemesanan']);
        if (dt == null) continue;
        if (dt.isAfter(now)) continue;

        // 🔥 Hanya hitung yang sudah dibayar untuk grafik penjualan
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status != 'sudah dibayar') continue;

        DateTime key;

        // 🔥 PERBAIKAN UTAMA: Untuk "Hari Ini", group by JAM
        if (range == "Hari Ini") {
          key = DateTime(dt.year, dt.month, dt.day, dt.hour); // Group by hour
          print(
            '⏰ Data: ${DateFormat('HH:mm').format(dt)} -> key: ${key.hour}:00',
          );
        } else {
          key = DateTime(dt.year, dt.month, dt.day); // Group by day
        }

        final previousValue = hasil[key] ?? 0;
        final newValue = previousValue + _toInt(data['totalHarga']);
        hasil[key] = newValue;

        print(
          '   💰 ${doc.id}: ${data['namaPemesan']} - Rp ${_toInt(data['totalHarga'])} -> Total: Rp $newValue',
        );
        processedCount++;
      }

      print('✅ Data diproses: $processedCount documents');

      // 🔥 PERBAIKAN: Isi semua jam untuk "Hari Ini" dengan cara yang benar
      if (range == "Hari Ini") {
        final startOfDay = DateTime(now.year, now.month, now.day);
        final currentHour = now.hour;

        print('🕒 Mengisi jam dari 00 sampai $currentHour');

        // Isi semua jam dari 00 sampai jam sekarang
        for (int hour = 0; hour <= currentHour; hour++) {
          final hourKey = DateTime(now.year, now.month, now.day, hour);
          // 🔥 PERBAIKAN: Gunakan operator [] untuk memastikan semua jam ada
          if (!hasil.containsKey(hourKey)) {
            hasil[hourKey] = 0;
            print('   ➕ Jam ${hour.toString().padLeft(2, '0')}:00 -> 0');
          }
        }
      } else if (range == "Minggu Ini") {
        for (int i = 0; i < 7; i++) {
          final d = startDate.add(Duration(days: i));
          if (!d.isAfter(now)) {
            hasil.putIfAbsent(d, () => 0);
          }
        }
      } else {
        final totalDays = DateTime(now.year, now.month + 1, 0).day;
        for (int i = 1; i <= totalDays; i++) {
          final d = DateTime(now.year, now.month, i);
          if (d.isAfter(now)) break;
          hasil.putIfAbsent(d, () => 0);
        }
      }

      // 🔥 PERBAIKAN: Pastikan hasil diurutkan dengan benar
      final sortedEntries =
          hasil.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

      print('🎯 FINAL Grafik data ($range): ${sortedEntries.length} entries');
      for (var entry in sortedEntries) {
        if (range == "Hari Ini") {
          print(
            '   🕒 ${entry.key.hour.toString().padLeft(2, '0')}:00 -> Rp ${entry.value}',
          );
        } else {
          print(
            '   📅 ${DateFormat('dd/MM').format(entry.key)} -> Rp ${entry.value}',
          );
        }
      }

      return Map.fromEntries(sortedEntries);
    } catch (e) {
      print('❌ Error getDataPenjualan: $e');
      return {};
    }
  }

  // 🔥 DEBUG: Method untuk test data belanja
  Future<void> _debugBelanjaData() async {
    try {
      final uid = _firestoreService.currentUserId;
      if (uid == null) return;

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('catatan_belanja')
              .get();

      print('🔍 DEBUG Belanja Data:');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('   📄 ${doc.id}:');
        print('      Fields: ${data.keys}');
        print('      totalBelanja: ${data['totalBelanja']}');
        print('      total: ${data['total']}');
        print('      jumlah: ${data['jumlah']}');
        print('      tanggal: ${data['tanggal']}');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  // 🔥 PERBAIKAN: Popup Laporan dengan debug info
  Future<void> _showLaporanDialog() async {
    // 🔥 DEBUG: Cek data belanja
    await _debugBelanjaData();

    final totalPenjualan = await getTotalPenjualanHariIni();
    final totalBelanja = await getTotalBelanjaHariIni();
    final jumlahPesanan = await getJumlahPesananHariIni();

    print('📋 Laporan Data:');
    print('   Penjualan: $totalPenjualan');
    print('   Belanja: $totalBelanja');
    print('   Pesanan: $jumlahPesanan');

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        size: 46,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Laporan Hari Ini",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: Colors.blueAccent.withOpacity(0.3),
                        thickness: 1,
                      ),
                      const SizedBox(height: 10),
                      _buildLaporanItem(
                        "Total Penjualan",
                        formatRupiah(totalPenjualan),
                        icon: Icons.attach_money_rounded,
                        color: Colors.green,
                      ),
                      _buildLaporanItem(
                        "Total Belanja",
                        formatRupiah(totalBelanja),
                        icon: Icons.shopping_cart_outlined,
                        color: Colors.redAccent,
                      ),
                      _buildLaporanItem(
                        "Jumlah Pesanan",
                        "$jumlahPesanan Pesanan",
                        icon: Icons.receipt_long_rounded,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 26),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Tutup",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLaporanItem(
    String title,
    String value, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.blueAccent,
                decoration: TextDecoration.none,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.blueAccent,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatCardWithComparison({
    required String title,
    required Future<int> futureToday,
    required Future<int> futureYesterday,
    String? suffixLabel,
    bool isCount = false,
  }) {
    return FutureBuilder<List<int>>(
      future: Future.wait([futureToday, futureYesterday]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        final int todayVal = snapshot.data![0];
        final int yesterdayVal = snapshot.data![1];

        double percent = 0;
        if (yesterdayVal != 0) {
          percent = ((todayVal - yesterdayVal) / yesterdayVal) * 100;
        } else if (todayVal != 0 && yesterdayVal == 0) {
          percent = 100.0;
        } else {
          percent = 0.0;
        }

        final bool positive = percent >= 0;
        final Color changeColor = positive ? Colors.green : Colors.red;
        final String percentText =
            "${positive ? '+' : ''}${percent.toStringAsFixed(1)}% ${suffixLabel ?? 'vs kemarin'}";

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                isCount ? '$todayVal' : formatRupiah(todayVal),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                percentText,
                style: TextStyle(color: changeColor, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  List<double> _smoothListConditional(List<double> values) {
    if (values.length <= 2) return values;
    final out = List<double>.from(values);
    for (int i = 1; i < values.length - 1; i++) {
      if (values[i - 1] > 0 && values[i] > 0 && values[i + 1] > 0) {
        out[i] = (values[i - 1] + values[i] + values[i + 1]) / 3;
      } else {
        out[i] = values[i];
      }
    }
    return out;
  }

  Widget buildChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Grafik Penjualan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRange,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.blueAccent,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  items:
                      ["Hari Ini", "Minggu Ini", "Bulan Ini"].map((e) {
                        IconData icon =
                            e == "Hari Ini"
                                ? Icons.today_outlined
                                : e == "Minggu Ini"
                                ? Icons.calendar_view_week_outlined
                                : Icons.calendar_month_outlined;
                        return DropdownMenuItem(
                          value: e,
                          child: Row(
                            children: [
                              Icon(icon, size: 18, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(e),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRange = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<Map<DateTime, int>>(
          future: getDataPenjualan(_selectedRange),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              print('❌ Grafik error: ${snapshot.error}');
              return SizedBox(
                height: 160,
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 160,
                child: Center(child: Text('Tidak ada data penjualan')),
              );
            }

            final dataMap = snapshot.data!;
            final entries =
                dataMap.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));

            final rawYs = entries.map((e) => e.value.toDouble()).toList();
            final smoothedYs = _smoothListConditional(rawYs);

            final spots = List<FlSpot>.generate(
              smoothedYs.length,
              (i) => FlSpot(i.toDouble(), smoothedYs[i]),
            );

            // 🔥 PERBAIKAN: Format label untuk "Hari Ini" dengan jam
            final labels =
                entries.map((e) {
                  final d = e.key;
                  if (_selectedRange == "Hari Ini") {
                    // Format jam dengan leading zero (00, 01, 02, ...)
                    return '${d.hour.toString().padLeft(2, '0')}:00';
                  } else if (_selectedRange == "Minggu Ini") {
                    return DateFormat('E').format(d); // Mon, Tue, Wed, etc.
                  } else {
                    return DateFormat('d').format(d); // 1, 2, 3, etc.
                  }
                }).toList();

            double minY = 0;
            double maxY =
                spots.isEmpty
                    ? 0
                    : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
            if (maxY == 0) maxY = 1000;
            final padding = maxY * 0.15;
            maxY += padding;

            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: Colors.blueAccent,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blueAccent.withOpacity(0.12),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= labels.length)
                              return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[idx],
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine:
                          (v) => FlLine(
                            color: Colors.grey.withOpacity(0.08),
                            strokeWidth: 1,
                          ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((t) {
                            final idx = t.x.toInt();
                            final label =
                                (idx >= 0 && idx < labels.length)
                                    ? labels[idx]
                                    : '';
                            final int rawVal =
                                (idx >= 0 && idx < entries.length)
                                    ? entries[idx].value
                                    : t.y.toInt();
                            final txt = formatRupiah(rawVal);
                            return LineTooltipItem(
                              '$label\n$txt',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildQuickMenuItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 92,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        children: [
          const SidebarWidget(activeMenu: "Dashboard"),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: buildStatCardWithComparison(
                          title: "Total Penjualan",
                          futureToday: getTotalPenjualanHariIni(),
                          futureYesterday: getTotalPenjualanKemarin(),
                          suffixLabel: "vs kemarin",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: buildStatCardWithComparison(
                          title: "Jumlah Pesanan",
                          futureToday: getJumlahPesananHariIni(),
                          futureYesterday: getJumlahPesananKemarin(),
                          suffixLabel: "vs kemarin",
                          isCount: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: buildStatCardWithComparison(
                          title: "Total Belanja",
                          futureToday: getTotalBelanjaHariIni(),
                          futureYesterday: getTotalBelanjaKemarin(),
                          suffixLabel: "vs kemarin",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  buildChart(),
                  const SizedBox(height: 32),
                  const Text(
                    "Menu Cepat",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      buildQuickMenuItem(
                        Icons.fastfood,
                        "Katalog Menu",
                        "Lihat menu",
                        Colors.blue,
                        () {
                          Navigator.pushNamed(context, '/katalog_menu');
                        },
                      ),
                      const SizedBox(width: 16),
                      buildQuickMenuItem(
                        Icons.receipt_long,
                        "Pesanan",
                        "Cek transaksi",
                        Colors.green,
                        () {
                          Navigator.pushNamed(context, '/daftar_pesanan');
                        },
                      ),
                      const SizedBox(width: 16),
                      buildQuickMenuItem(
                        Icons.shopping_cart,
                        "Belanja",
                        "Atur stok",
                        Colors.orange,
                        () {
                          Navigator.pushNamed(context, '/catatan_belanja');
                        },
                      ),
                      const SizedBox(width: 16),
                      buildQuickMenuItem(
                        Icons.bar_chart,
                        "Laporan",
                        "Lihat laporan",
                        Colors.purple,
                        () {
                          _showLaporanDialog();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
