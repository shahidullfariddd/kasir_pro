import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kasir_pro/widgets/sidebar_widget.dart';

class KatalogMenuScreen extends StatefulWidget {
  const KatalogMenuScreen({Key? key}) : super(key: key);

  @override
  State<KatalogMenuScreen> createState() => _KatalogMenuScreenState();
}

class _KatalogMenuScreenState extends State<KatalogMenuScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  String? get currentUserId => _auth.currentUser?.uid;

  /// === Upload ke Cloudinary ===
  Future<String?> uploadImageToCloudinary({
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    const cloudName = 'doacsjhtn';
    const uploadPreset = 'katalogmenu';
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset;

    if (kIsWeb && imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'upload.png',
        ),
      );
    } else if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
    } else {
      return null;
    }

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);
    final data = json.decode(responseData.body);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      debugPrint('Upload gagal: ${data['error']}');
      return null;
    }
  }

  /// === Dialog Tambah / Edit Menu ===
  Future<void> showMenuDialog({DocumentSnapshot? doc}) async {
    if (currentUserId == null) return;

    final namaController = TextEditingController(text: doc?['nama'] ?? '');
    final hargaController = TextEditingController(
      text: doc != null ? "${doc['harga']}" : "",
    );
    final deskripsiController = TextEditingController(
      text: doc?['deskripsi'] ?? '',
    );

    String kategori = doc?['kategori'] ?? 'Main Course';
    String? imageUrl = doc?['gambarUrl'];
    File? imageFile;
    Uint8List? imageBytes;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 60,
                vertical: 40,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                width: 600,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Judul
                        Text(
                          doc == null ? 'Tambah Menu' : 'Edit Menu',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Nama Menu
                        TextField(
                          controller: namaController,
                          decoration: InputDecoration(
                            labelText: 'Nama Menu',
                            labelStyle: const TextStyle(color: Colors.grey),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E88E5),
                                width: 2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Harga
                        TextField(
                          controller: hargaController,
                          decoration: InputDecoration(
                            labelText: 'Harga',
                            labelStyle: const TextStyle(color: Colors.grey),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E88E5),
                                width: 2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixText: 'Rp ',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        // Kategori
                        DropdownButtonFormField<String>(
                          value: kategori,
                          items: const [
                            DropdownMenuItem(
                              value: 'Main Course',
                              child: Text('Main Course'),
                            ),
                            DropdownMenuItem(
                              value: 'Snack',
                              child: Text('Snack'),
                            ),
                            DropdownMenuItem(
                              value: 'Dessert',
                              child: Text('Dessert'),
                            ),
                            DropdownMenuItem(
                              value: 'Drink',
                              child: Text('Drink'),
                            ),
                          ],
                          onChanged:
                              (val) => setStateDialog(() => kategori = val!),
                          decoration: InputDecoration(
                            labelText: 'Tipe Menu',
                            labelStyle: const TextStyle(color: Colors.grey),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E88E5),
                                width: 2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Deskripsi
                        TextField(
                          controller: deskripsiController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi',
                            labelStyle: const TextStyle(color: Colors.grey),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E88E5),
                                width: 2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Preview Gambar
                        if (_isUploading)
                          Column(
                            children: const [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text("Sedang mengunggah gambar..."),
                            ],
                          )
                        else if (imageBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              imageBytes!,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (imageFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              imageFile!,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl!,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('Tidak ada gambar'),
                            ),
                          ),
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await _picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              if (kIsWeb) {
                                final bytes = await picked.readAsBytes();
                                setStateDialog(() {
                                  imageBytes = bytes;
                                  imageFile = null;
                                });
                              } else {
                                setStateDialog(() {
                                  imageFile = File(picked.path);
                                  imageBytes = null;
                                });
                              }
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Pilih Gambar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tombol Simpan & Batal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final nama = namaController.text.trim();
                                final deskripsi =
                                    deskripsiController.text.trim();
                                final harga =
                                    int.tryParse(
                                      hargaController.text.replaceAll(
                                        "Rp ",
                                        "",
                                      ),
                                    ) ??
                                    0;
                                if (nama.isEmpty || harga == 0) return;

                                try {
                                  if (imageFile != null || imageBytes != null) {
                                    setStateDialog(() => _isUploading = true);
                                    final uploadedUrl =
                                        await uploadImageToCloudinary(
                                          imageFile: imageFile,
                                          imageBytes: imageBytes,
                                        );
                                    setStateDialog(() => _isUploading = false);
                                    if (uploadedUrl != null)
                                      imageUrl = uploadedUrl;
                                  }

                                  final data = {
                                    'nama': nama,
                                    'harga': harga,
                                    'kategori': kategori,
                                    'deskripsi': deskripsi,
                                    'gambarUrl': imageUrl,
                                    'tanggalTambah':
                                        FieldValue.serverTimestamp(),
                                    'createdAt': FieldValue.serverTimestamp(),
                                  };

                                  final menuRef = _firestore
                                      .collection('users')
                                      .doc(currentUserId)
                                      .collection('menu');

                                  if (doc == null) {
                                    await menuRef.add(data);
                                  } else {
                                    await menuRef.doc(doc.id).update(data);
                                  }

                                  if (mounted) Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '✅ Menu berhasil disimpan!',
                                      ),
                                      backgroundColor: Color(0xFF1E88E5),
                                    ),
                                  );
                                } catch (e) {
                                  setStateDialog(() => _isUploading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Terjadi kesalahan: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Simpan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// === Hapus Menu ===
  Future<void> hapusMenu(String id) async {
    if (currentUserId == null) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Menu'),
            content: const Text('Yakin ingin menghapus menu ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (konfirmasi == true) {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('menu')
          .doc(id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    final menuStream =
        _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('menu')
            .orderBy('tanggalTambah', descending: true)
            .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        children: [
          const SidebarWidget(activeMenu: 'Katalog Menu'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Katalog Menu',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kelola menu dan harga produk Anda',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Cari menu...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => showMenuDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Menu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: menuStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('Belum ada menu.'));
                        }

                        final menus = snapshot.data!.docs;
                        return GridView.builder(
                          itemCount: menus.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 1.1,
                              ),
                          itemBuilder: (context, index) {
                            final menu = menus[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: Colors.grey.shade300,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        menu['gambarUrl'] ?? '',
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.image_not_supported,
                                                ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menu['nama'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          child: Text(
                                            menu['kategori'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Rp ${menu['harga']}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E88E5),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  onPressed:
                                                      () => showMenuDialog(
                                                        doc: menu,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    size: 18,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed:
                                                      () => hapusMenu(menu.id),
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
}
