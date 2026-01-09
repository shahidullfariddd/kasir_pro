import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../widgets/sidebar_widget.dart';

class AdministrasiScreen extends StatefulWidget {
  const AdministrasiScreen({Key? key}) : super(key: key);

  @override
  State<AdministrasiScreen> createState() => _AdministrasiScreenState();
}

class _AdministrasiScreenState extends State<AdministrasiScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String selectedFilter = 'Semua';
  DateTime? selectedDate;
  List<Map<String, dynamic>> currentOrders = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  // 🔹 Generator ID Pesanan (6 karakter huruf besar + angka)
  String generateOrderId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // 🔹 Print laporan
  Future<void> _generateAndPrintPDF() async {
    final pdf = pw.Document();
    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Center(
                child: pw.Text(
                  'Laporan Penjualan Harian',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                selectedDate == null
                    ? DateFormat(
                      "EEEE, d MMMM yyyy",
                      'id_ID',
                    ).format(DateTime.now())
                    : DateFormat(
                      "EEEE, d MMMM yyyy",
                      'id_ID',
                    ).format(selectedDate!),
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: [
                  'ID Pesanan',
                  'Waktu',
                  'Pelanggan',
                  'Jumlah Item',
                  'Total',
                  'Pembayaran',
                  'Status',
                ],
                data:
                    currentOrders.map((o) {
                      return [
                        o['customId'],
                        DateFormat('HH:mm').format(o['waktuPemesanan']),
                        o['namaPemesan'],
                        (o['menu'] as List).length.toString(),
                        currency.format(o['totalHarga']),
                        o['tipePembayaran'],
                        o['status'],
                      ];
                    }).toList(),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // 🔹 Ekspor PDF
  Future<void> _exportPDFFile() async {
    final pdf = pw.Document();
    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Center(
                child: pw.Text(
                  'Laporan Penjualan Harian',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                selectedDate == null
                    ? DateFormat(
                      "EEEE, d MMMM yyyy",
                      'id_ID',
                    ).format(DateTime.now())
                    : DateFormat(
                      "EEEE, d MMMM yyyy",
                      'id_ID',
                    ).format(selectedDate!),
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: [
                  'ID Pesanan',
                  'Waktu',
                  'Pelanggan',
                  'Jumlah Item',
                  'Total',
                  'Pembayaran',
                  'Status',
                ],
                data:
                    currentOrders.map((o) {
                      return [
                        o['customId'],
                        DateFormat('HH:mm').format(o['waktuPemesanan']),
                        o['namaPemesan'],
                        (o['menu'] as List).length.toString(),
                        currency.format(o['totalHarga']),
                        o['tipePembayaran'],
                        o['status'],
                      ];
                    }).toList(),
              ),
            ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'laporan_penjualan.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Row(
        children: [
          const SidebarWidget(activeMenu: "Administrasi"),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Laporan Penjualan Harian",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedDate == null
                                ? DateFormat(
                                  "EEEE, d MMMM yyyy",
                                  'id_ID',
                                ).format(DateTime.now())
                                : "Tanggal dipilih: ${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate!)}",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          buildTopButton(
                            Icons.date_range,
                            "Pilih Tanggal",
                            _pilihTanggal,
                          ),
                          const SizedBox(width: 8),
                          buildTopButton(
                            Icons.print,
                            "Print",
                            _generateAndPrintPDF,
                          ),
                          const SizedBox(width: 8),
                          buildTopButton(
                            Icons.picture_as_pdf,
                            "Ekspor PDF",
                            _exportPDFFile,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🔹 Isi utama
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser!.uid)
                              .collection('pesanan')
                              .orderBy('waktuPemesanan', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("Belum ada data pesanan."),
                          );
                        }

                        final allOrders =
                            snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              String? storedId = data['customId'];
                              if (storedId == null) {
                                storedId = generateOrderId();
                                doc.reference.update({'customId': storedId});
                              }
                              return {
                                'customId': storedId,
                                'namaPemesan': data['namaPemesan'] ?? '-',
                                'waktuPemesanan':
                                    (data['waktuPemesanan'] as Timestamp)
                                        .toDate(),
                                'totalHarga': data['totalHarga'] ?? 0,
                                'tipePembayaran': data['tipePembayaran'] ?? '-',
                                'status': data['status'] ?? '-',
                                'menu': data['menu'] ?? [],
                              };
                            }).toList();

                        final filteredByDate =
                            selectedDate == null
                                ? allOrders
                                : allOrders.where((order) {
                                  final date =
                                      order['waktuPemesanan'] as DateTime;
                                  return date.year == selectedDate!.year &&
                                      date.month == selectedDate!.month &&
                                      date.day == selectedDate!.day;
                                }).toList();

                        final filteredOrders =
                            selectedFilter == 'Semua'
                                ? filteredByDate
                                : filteredByDate
                                    .where(
                                      (order) =>
                                          order['tipePembayaran'] ==
                                          selectedFilter,
                                    )
                                    .toList();

                        currentOrders = filteredOrders;

                        if (filteredOrders.isEmpty) {
                          return const Center(
                            child: Text("Tidak ada pesanan pada tanggal ini."),
                          );
                        }

                        final totalPenjualan = filteredOrders.fold<int>(
                          0,
                          (sum, item) =>
                              sum + ((item['totalHarga'] ?? 0) as int),
                        );
                        final totalCash = filteredOrders
                            .where((o) => o['tipePembayaran'] == 'Cash')
                            .fold<int>(
                              0,
                              (sum, o) => sum + ((o['totalHarga'] ?? 0) as int),
                            );
                        final totalQR = filteredOrders
                            .where((o) => o['tipePembayaran'] == 'QRIS')
                            .fold<int>(
                              0,
                              (sum, o) => sum + ((o['totalHarga'] ?? 0) as int),
                            );

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: buildSummaryCard(
                                      "Total Penjualan",
                                      currency.format(totalPenjualan),
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: buildSummaryCard(
                                      "Pembayaran Tunai",
                                      currency.format(totalCash),
                                      Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: buildSummaryCard(
                                      "Pembayaran QRIS",
                                      currency.format(totalQR),
                                      Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: buildSummaryCard(
                                      "Jumlah Pesanan",
                                      "${filteredOrders.length}",
                                      Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // 🔹 Tabel + Filter Pembayaran Stylish
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade200,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Daftar Pesanan",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          // 🔹 Tombol kategori stylish
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              children:
                                                  [
                                                    'Semua',
                                                    'Cash',
                                                    'QRIS',
                                                  ].map((filter) {
                                                    final bool isActive =
                                                        selectedFilter ==
                                                        filter;
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                          ),
                                                      child: AnimatedContainer(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 250,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              isActive
                                                                  ? Colors
                                                                      .blue
                                                                      .shade600
                                                                  : Colors
                                                                      .white,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          boxShadow:
                                                              isActive
                                                                  ? [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .blue
                                                                          .withOpacity(
                                                                            0.25,
                                                                          ),
                                                                      blurRadius:
                                                                          8,
                                                                      offset:
                                                                          const Offset(
                                                                            0,
                                                                            3,
                                                                          ),
                                                                    ),
                                                                  ]
                                                                  : [],
                                                          border: Border.all(
                                                            color:
                                                                isActive
                                                                    ? Colors
                                                                        .blue
                                                                        .shade600
                                                                    : Colors
                                                                        .grey
                                                                        .shade300,
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              selectedFilter =
                                                                  filter;
                                                            });
                                                          },
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      14,
                                                                  vertical: 8,
                                                                ),
                                                            child: Text(
                                                              filter,
                                                              style: TextStyle(
                                                                color:
                                                                    isActive
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black87,
                                                                fontWeight:
                                                                    isActive
                                                                        ? FontWeight
                                                                            .bold
                                                                        : FontWeight
                                                                            .w500,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 1200,
                                        ),
                                        child: DataTable(
                                          columnSpacing: 40,
                                          headingRowHeight: 48,
                                          dataRowHeight: 44,
                                          columns: const [
                                            DataColumn(
                                              label: Text(
                                                "ID Pesanan",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Waktu",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Pelanggan",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Jumlah Item",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Total",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Pembayaran",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Status",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                          rows:
                                              filteredOrders.map((order) {
                                                final waktu = DateFormat(
                                                  "HH:mm",
                                                ).format(
                                                  order['waktuPemesanan'],
                                                );
                                                final jumlahItem =
                                                    (order['menu'] as List)
                                                        .length;

                                                Color bgColor;
                                                Color textColor;
                                                if (order['status'] ==
                                                    "Selesai") {
                                                  bgColor =
                                                      Colors.green.shade100;
                                                  textColor =
                                                      Colors.green.shade800;
                                                } else if (order['status'] ==
                                                        "Menunggu Pembayaran" ||
                                                    order['status'] ==
                                                        "Diproses") {
                                                  bgColor =
                                                      Colors.orange.shade100;
                                                  textColor =
                                                      Colors.orange.shade800;
                                                } else {
                                                  bgColor =
                                                      Colors.grey.shade200;
                                                  textColor =
                                                      Colors.grey.shade700;
                                                }

                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(order['customId']),
                                                    ),
                                                    DataCell(Text(waktu)),
                                                    DataCell(
                                                      Text(
                                                        order['namaPemesan'],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text("$jumlahItem item"),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        currency.format(
                                                          order['totalHarga'],
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        order['tipePembayaran'],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 3,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: bgColor,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          order['status'],
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: textColor,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Pilih tanggal
  void _pilihTanggal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // 🔹 Tombol di header
  Widget buildTopButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // 🔹 Kartu ringkasan
  Widget buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
