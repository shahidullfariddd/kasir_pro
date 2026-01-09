import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pro/services/firestore_services.dart';
import 'package:kasir_pro/widgets/sidebar_widget.dart';

class CatatanBelanjaScreen extends StatefulWidget {
  const CatatanBelanjaScreen({Key? key}) : super(key: key);

  @override
  State<CatatanBelanjaScreen> createState() => _CatatanBelanjaScreenState();
}

class _CatatanBelanjaScreenState extends State<CatatanBelanjaScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _belanjaList = [];
  bool _isLoading = true;

  final NumberFormat _currencyFmt = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadBelanja();
  }

  Future<void> _loadBelanja() async {
    setState(() => _isLoading = true);
    try {
      final data = await _firestoreService.getBelanja();
      setState(() {
        _belanjaList = data;
      });
    } catch (e, st) {
      debugPrint('Error loading belanja: $e\n$st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _tambahBelanjaDialog() async {
    final TextEditingController itemCtrl = TextEditingController();
    String tipeBelanja = 'Bahan';
    final TextEditingController jumlahCtrl = TextEditingController();
    final TextEditingController hargaPerUnitCtrl = TextEditingController();
    final TextEditingController keteranganCtrl = TextEditingController();
    DateTime? tanggalDipilih;

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx2, setStateDialog) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                insetPadding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Catatan Belanja',
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF009EFF),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Nama Item
                        TextField(
                          controller: itemCtrl,
                          style: GoogleFonts.roboto(),
                          decoration: InputDecoration(
                            labelText: 'Nama Item',
                            labelStyle: GoogleFonts.roboto(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Tipe Belanja
                        DropdownButtonFormField<String>(
                          value: tipeBelanja,
                          items: const [
                            DropdownMenuItem(
                              value: 'Bahan',
                              child: Text('Bahan'),
                            ),
                            DropdownMenuItem(
                              value: 'Operasional',
                              child: Text('Operasional'),
                            ),
                          ],
                          onChanged:
                              (v) => setStateDialog(
                                () => tipeBelanja = v ?? 'Bahan',
                              ),
                          decoration: InputDecoration(
                            labelText: 'Tipe Belanja',
                            labelStyle: GoogleFonts.roboto(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          style: GoogleFonts.roboto(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        // Jumlah
                        TextField(
                          controller: jumlahCtrl,
                          style: GoogleFonts.roboto(),
                          decoration: InputDecoration(
                            labelText: 'Jumlah',
                            labelStyle: GoogleFonts.roboto(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        // Harga per unit
                        TextField(
                          controller: hargaPerUnitCtrl,
                          style: GoogleFonts.roboto(),
                          decoration: InputDecoration(
                            labelText: 'Harga/unit (Rp)',
                            labelStyle: GoogleFonts.roboto(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        // Keterangan
                        TextField(
                          controller: keteranganCtrl,
                          style: GoogleFonts.roboto(),
                          decoration: InputDecoration(
                            labelText: 'Keterangan',
                            labelStyle: GoogleFonts.roboto(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Pilih Tanggal
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tanggalDipilih == null
                                      ? 'Pilih tanggal pembelian'
                                      : DateFormat(
                                        'dd MMM yyyy',
                                      ).format(tanggalDipilih!),
                                  style: GoogleFonts.roboto(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: ctx2,
                                  initialDate: tanggalDipilih ?? now,
                                  firstDate: DateTime(now.year - 5),
                                  lastDate: DateTime(now.year + 5),
                                );
                                if (picked != null) {
                                  setStateDialog(() => tanggalDipilih = picked);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009EFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Pilih Tanggal',
                                style: GoogleFonts.roboto(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Tombol aksi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.roboto(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  await showDialog(
                                    context: context,
                                    builder:
                                        (ctx) => AlertDialog(
                                          title: const Text('Belum Login'),
                                          content: const Text(
                                            'Silakan login untuk menambahkan catatan belanja.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(ctx),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                  );
                                  return;
                                }

                                final item = itemCtrl.text.trim();
                                if (item.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nama item wajib diisi'),
                                    ),
                                  );
                                  return;
                                }

                                final jumlah =
                                    int.tryParse(jumlahCtrl.text.trim()) ?? 0;
                                final hargaPerUnit =
                                    int.tryParse(
                                      hargaPerUnitCtrl.text.trim(),
                                    ) ??
                                    0;

                                final int total =
                                    (jumlah > 0 && hargaPerUnit > 0)
                                        ? (jumlah * hargaPerUnit)
                                        : (hargaPerUnit > 0 ? hargaPerUnit : 0);

                                final keterangan = keteranganCtrl.text.trim();
                                final tanggal =
                                    tanggalDipilih ?? DateTime.now();

                                try {
                                  await _firestoreService.addBelanja(
                                    item: item,
                                    tipeBelanja: tipeBelanja,
                                    jumlah: jumlah,
                                    total: total,
                                    keterangan: keterangan,
                                    tanggal: tanggal,
                                  );

                                  Navigator.pop(ctx);
                                  await _loadBelanja();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Catatan belanja berhasil ditambahkan',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  debugPrint('Error addBelanja: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Gagal menambahkan catatan: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009EFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 24,
                                ),
                              ),
                              child: Text(
                                'Simpan',
                                style: GoogleFonts.roboto(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildBelanjaRow(Map<String, dynamic> belanja) {
    final String id = belanja['id'] ?? '';
    final String item = belanja['item'] ?? '-';
    final String tipe = belanja['tipeBelanja'] ?? '-';
    final int jumlah =
        (belanja['jumlah'] is int)
            ? belanja['jumlah'] as int
            : int.tryParse('${belanja['jumlah']}') ?? 0;
    final int total =
        (belanja['total'] is int)
            ? belanja['total'] as int
            : int.tryParse('${belanja['total']}') ?? 0;
    final String keterangan = belanja['keterangan'] ?? '-';

    DateTime? tanggal;
    try {
      final t = belanja['tanggal'];
      if (t is Timestamp) {
        tanggal = t.toDate();
      } else if (t is DateTime) {
        tanggal = t;
      } else if (t is String) {
        tanggal = DateTime.tryParse(t);
      }
    } catch (_) {
      tanggal = null;
    }

    Color tipeColor;
    switch (tipe.toLowerCase()) {
      case 'bahan':
      case 'bahan makanan':
        tipeColor = Colors.green;
        break;
      case 'operasional':
        tipeColor = Colors.orange;
        break;
      default:
        tipeColor = Colors.grey;
    }

    return ListTile(
      title: Text(item, style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tipeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tipe,
                  style: GoogleFonts.roboto(
                    color: tipeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Jumlah: $jumlah',
                style: GoogleFonts.roboto(color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Text(
                tanggal != null
                    ? DateFormat('dd MMM yyyy').format(tanggal)
                    : '-',
                style: GoogleFonts.roboto(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Keterangan: $keterangan',
            style: GoogleFonts.roboto(color: Colors.grey),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Rp ${_currencyFmt.format(total)}',
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User belum login')),
                );
                return;
              }

              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: Text('Hapus Catatan', style: GoogleFonts.roboto()),
                      content: Text(
                        'Yakin ingin menghapus catatan belanja ini?',
                        style: GoogleFonts.roboto(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Batal', style: GoogleFonts.roboto()),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Hapus', style: GoogleFonts.roboto()),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                try {
                  await _firestoreService.deleteBelanja(id);
                  await _loadBelanja();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Catatan dihapus')),
                  );
                } catch (e) {
                  debugPrint('Error deleteBelanja: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const SidebarWidget(activeMenu: 'Catatan Belanja'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Belanja',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola dan catat semua pembelian bahan dan operasional',
                    style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() {}),
                          style: GoogleFonts.roboto(),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Cari item belanja...',
                            hintStyle: GoogleFonts.roboto(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _tambahBelanjaDialog,
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Tambah Belanja',
                          style: GoogleFonts.roboto(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009EFF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _belanjaList.isEmpty
                              ? Center(
                                child: Text(
                                  'Belum ada catatan belanja',
                                  style: GoogleFonts.roboto(),
                                ),
                              )
                              : ListView.separated(
                                itemCount: _belanjaList.length,
                                separatorBuilder:
                                    (_, __) => const Divider(height: 1),
                                itemBuilder:
                                    (context, index) =>
                                        _buildBelanjaRow(_belanjaList[index]),
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
