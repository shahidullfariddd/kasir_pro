import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pro/services/firestore_services.dart';
import 'package:kasir_pro/widgets/sidebar_widget.dart';

class DaftarPesananScreen extends StatefulWidget {
  const DaftarPesananScreen({Key? key}) : super(key: key);

  @override
  State<DaftarPesananScreen> createState() => _DaftarPesananScreenState();
}

class _DaftarPesananScreenState extends State<DaftarPesananScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _filterWaktu = 'Hari Ini';
  String _filterStatus = 'Semua Status';
  String _searchQuery = '';

  // 🔥 PERBAIKAN: Method _buildPesananStream yang sudah diperbaiki
  Stream<QuerySnapshot> _buildPesananStream() {
    print(
      '🔄 [DaftarPesanan] Building stream with status: "$_filterStatus", waktu: "$_filterWaktu"',
    );

    return _firestoreService.getPesananStream(
      statusFilter: _filterStatus == 'Semua Status' ? null : _filterStatus,
      waktuFilter: _filterWaktu,
    );
  }

  // 🔹 Konfirmasi ubah status pembayaran
  void _showKonfirmasiStatus(
    String docId,
    String currentStatus,
    String namaPemesan,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Konfirmasi Status',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, a1, a2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header dengan gradient background
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.payment_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Konfirmasi Status Pembayaran",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Atas nama: $namaPemesan",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content area
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          "Ubah status pembayaran pesanan ini?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Status saat ini
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Status Saat Ini:",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    currentStatus,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getStatusColor(
                                      currentStatus,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  currentStatus,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(currentStatus),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            // Tombol Batal
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Batal",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Tombol Ubah Status
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade600,
                                      Colors.blue.shade400,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _ubahStatusPembayaran(
                                      docId,
                                      currentStatus,
                                      namaPemesan,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Ubah Status",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondary, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  // 🔹 Ubah status pembayaran
  Future<void> _ubahStatusPembayaran(
    String docId,
    String currentStatus,
    String namaPemesan,
  ) async {
    final newStatus =
        currentStatus == 'Belum dibayar' ? 'Sudah dibayar' : 'Belum dibayar';

    try {
      await _firestoreService.updatePesananStatus(docId, newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Status $namaPemesan diubah menjadi $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal mengubah status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🔹 Format tiap baris pesanan
  Widget _buildPesananRow(Map<String, dynamic> data, String docId) {
    final namaPemesan = data['namaPemesan'] ?? '-';
    final totalHarga = data['totalHarga'] ?? 0;
    final tipePembayaran = data['tipePembayaran'] ?? '-';
    final status = data['status'] ?? 'Belum dibayar';
    final waktuPemesanan = (data['waktuPemesanan'] as Timestamp?)?.toDate();

    final tanggalFormatted =
        waktuPemesanan != null
            ? DateFormat('dd MMM yyyy, HH:mm').format(waktuPemesanan)
            : '-';

    final Color statusColor = _getStatusColor(status);

    // 🔸 Ambil daftar menu dari data
    final List<dynamic> menuList = data['menu'] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ExpansionTile(
        leading: const Icon(Icons.receipt_long, color: Colors.blue),
        title: Text(
          namaPemesan,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$tanggalFormatted\n$tipePembayaran'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rp ${NumberFormat("#,###", "id_ID").format(totalHarga)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // Status yang bisa diklik untuk pesanan "Belum dibayar"
            if (status == 'Belum dibayar' || status == 'Sudah dibayar')
              GestureDetector(
                onTap: () => _showKonfirmasiStatus(docId, status, namaPemesan),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (status == 'Belum dibayar' ||
                          status == 'Sudah dibayar') ...[
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 12, color: statusColor),
                      ],
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        // 🔸 Detail menu ditampilkan saat di-expand
        children:
            menuList.map((menuItem) {
              final namaMenu = menuItem['nama'] ?? '-';
              final hargaMenu = menuItem['harga'] ?? 0;
              final jumlah = menuItem['jumlah'] ?? 1;
              return ListTile(
                dense: true,
                title: Text('$namaMenu (x$jumlah)'),
                trailing: Text(
                  'Rp ${NumberFormat("#,###", "id_ID").format(hargaMenu)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
      ),
    );
  }

  // 🔹 Helper function untuk warna status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sudah dibayar':
        return Colors.green;
      case 'Belum dibayar':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSummary(List<QueryDocumentSnapshot> docs) {
    final totalPesanan = docs.length;

    final totalHarga = docs.fold<int>(0, (int acc, QueryDocumentSnapshot doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final dynamic v = data['totalHarga'];
      int value = 0;
      if (v is int) {
        value = v;
      } else if (v is double) {
        value = v.toInt();
      } else if (v is String) {
        // jika tersimpan sebagai string angka, coba parse
        value = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
      return acc + value;
    });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: const Color(0xFF009EFF).withOpacity(0.1),
        child: ListTile(
          title: Text(
            'Total $_filterWaktu',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('Jumlah Pesanan: $totalPesanan'),
          trailing: Text(
            'Rp ${NumberFormat("#,###", "id_ID").format(totalHarga)}',
            style: const TextStyle(
              color: Color(0xFF009EFF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const SidebarWidget(activeMenu: 'Daftar Pesanan'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftar Pesanan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kelola dan lihat semua pesanan Anda',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  // 🔹 Search dan filter
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Cari berdasarkan nama pelanggan...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged:
                              (val) => setState(
                                () => _searchQuery = val.toLowerCase(),
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _filterWaktu,
                        items: const [
                          DropdownMenuItem(
                            value: 'Hari Ini',
                            child: Text('Hari Ini'),
                          ),
                          DropdownMenuItem(
                            value: 'Minggu Ini',
                            child: Text('Minggu Ini'),
                          ),
                          DropdownMenuItem(
                            value: 'Bulan Ini',
                            child: Text('Bulan Ini'),
                          ),
                        ],
                        onChanged: (val) => setState(() => _filterWaktu = val!),
                      ),
                      const SizedBox(width: 8),
                      // 🔹 PERBAIKAN: Filter status pembayaran - SESUAI FIRESTORE
                      DropdownButton<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 'Semua Status',
                            child: Text('Semua Status'),
                          ),
                          DropdownMenuItem(
                            value: 'Belum dibayar', // ← SAMA dengan Firestore
                            child: Text('Belum dibayar'),
                          ),
                          DropdownMenuItem(
                            value: 'Sudah dibayar', // ← SAMA dengan Firestore
                            child: Text('Sudah dibayar'),
                          ),
                        ],
                        onChanged:
                            (val) => setState(() => _filterStatus = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 🔹 Tampilan daftar pesanan
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _buildPesananStream(),
                        builder: (context, snapshot) {
                          // 🔥 DEBUG: Tambahkan printing untuk troubleshooting
                          if (snapshot.hasData) {
                            final docs = snapshot.data!.docs;
                            print(
                              '📊 [DaftarPesanan] Data received: ${docs.length} documents',
                            );
                            for (var doc in docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              print(
                                '   📝 ${doc.id}: ${data['namaPemesan']} - Status: "${data['status']}"',
                              );
                            }
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            print('⏳ [DaftarPesanan] Loading data...');
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            print('❌ [DaftarPesanan] Error: ${snapshot.error}');
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            print(
                              'ℹ️ [DaftarPesanan] No data found with current filters',
                            );
                            print('   Filter Status: "$_filterStatus"');
                            print('   Filter Waktu: "$_filterWaktu"');
                            return const Center(
                              child: Text('Belum ada pesanan.'),
                            );
                          }

                          final docs = snapshot.data!.docs;
                          final filtered =
                              docs.where((doc) {
                                final nama =
                                    (doc['namaPemesan'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                return nama.contains(_searchQuery);
                              }).toList();

                          return Column(
                            children: [
                              _buildSummary(filtered),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder:
                                      (context, index) => _buildPesananRow(
                                        filtered[index].data()
                                            as Map<String, dynamic>,
                                        filtered[index].id, // Pass document ID
                                      ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
}
