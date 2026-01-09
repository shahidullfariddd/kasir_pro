import 'dart:typed_data'; // Untuk Uint8List

import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasir_pro/providers/user_profile_provider.dart';
import 'package:kasir_pro/services/cloudinary_service.dart';
import 'package:kasir_pro/services/firestore_services.dart';
import 'package:kasir_pro/widgets/sidebar_widget.dart';
import 'package:provider/provider.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  TextEditingController _storeNameController = TextEditingController();
  TextEditingController _storeAddressController = TextEditingController();
  TextEditingController _storePhoneController = TextEditingController();
  TextEditingController _receiptFooterController = TextEditingController();

  TextEditingController _qrisBankController = TextEditingController();
  TextEditingController _qrisAccountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      final storeData = await _firestoreService.getStoreSettings();
      if (storeData != null) {
        setState(() {
          _storeNameController.text = storeData['storeName'] ?? '';
          _storeAddressController.text = storeData['storeAddress'] ?? '';
          _storePhoneController.text = storeData['storePhone'] ?? '';
          _receiptFooterController.text = storeData['receiptFooter'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading store data: $e');
    }
  }

  Future<void> _uploadQrisImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        // Tampilkan dialog input info QRIS
        await _showQrisInfoDialog(pickedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  // Helper function untuk menampilkan gambar dari XFile
  Widget _buildImageFromXFile(
    XFile imageFile, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return FutureBuilder<Uint8List>(
      future: imageFile.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
          );
        }
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Future<void> _showQrisInfoDialog(XFile imageFile) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Informasi QRIS'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview gambar - menggunakan helper function
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildImageFromXFile(
                      imageFile,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _qrisBankController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Bank/E-Wallet',
                      hintText: 'Contoh: GoPay, OVO, BCA',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _qrisAccountController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pemilik QRIS',
                      hintText: 'Nama sesuai akun',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_qrisBankController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Masukkan nama bank/ewallet'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  await _processQrisUpload(imageFile);
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  Future<void> _processQrisUpload(XFile imageFile) async {
    try {
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );

      // Tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Upload ke Cloudinary - gunakan XFile langsung
      final uploadResult = await _cloudinaryService.uploadImage(
        imageFile, // Kirim XFile langsung
        folder: 'qris_images',
      );

      if (uploadResult != null && uploadResult['secure_url'] != null) {
        final qrisUrl = uploadResult['secure_url'];

        // Update user profile dengan QRIS baru
        await userProfileProvider.updateQris(
          imageUrl: qrisUrl,
          bankName: _qrisBankController.text,
          accountName: _qrisAccountController.text,
        );

        // Clear form
        _qrisBankController.clear();
        _qrisAccountController.clear();

        // Tutup loading
        if (mounted) Navigator.pop(context);

        // Tampilkan success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ QRIS berhasil diupload!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Gagal upload ke Cloudinary');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Gagal upload QRIS: $e')));
    }
  }

  Future<void> _saveStoreSettings() async {
    try {
      await _firestoreService.updateStoreSettings(
        storeName: _storeNameController.text,
        storeAddress: _storeAddressController.text,
        storePhone: _storePhoneController.text,
        receiptFooter: _receiptFooterController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pengaturan toko berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Gagal menyimpan: $e')));
    }
  }

  void _showEditProfileDialog() {
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final user = userProfileProvider.userProfile;

    TextEditingController nameController = TextEditingController(
      text: user?.name ?? '',
    );
    TextEditingController phoneController = TextEditingController(
      text: user?.phone ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'No. Telepon',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await userProfileProvider.updateProfile(
                    name: nameController.text,
                    phone: phoneController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil berhasil diperbarui')),
                  );
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final user = userProfileProvider.userProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          const SidebarWidget(activeMenu: 'Profil'),

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profil & Pengaturan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column - Profil & QRIS
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                // Profil Saya Card
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Profil Saya',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Kelola informasi profil Anda',
                                        ),
                                        const Divider(height: 32),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 36,
                                              backgroundColor: const Color(
                                                0xFFE5E7EB,
                                              ),
                                              backgroundImage:
                                                  user?.photoUrl != null
                                                      ? NetworkImage(
                                                        user!.photoUrl!,
                                                      )
                                                      : null,
                                              child:
                                                  user?.photoUrl == null
                                                      ? const Icon(
                                                        Icons.person,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      )
                                                      : null,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user?.name ?? 'Lexypoi',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const Text(
                                                    'Admin',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    user?.email ??
                                                        'lexypoi@gmail.com',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _showEditProfileDialog,
                                              icon: const Icon(Icons.edit),
                                              tooltip: 'Edit Profil',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          'Informasi Kontak',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        infoRow(
                                          Icons.email_outlined,
                                          user?.email ?? 'lexypoi@gmail.com',
                                        ),
                                        infoRow(
                                          Icons.phone_outlined,
                                          user?.phone ?? '081234567890',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // QRIS Settings Card
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'QRIS Pembayaran',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (user?.qrisImageUrl != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color:
                                                        Colors.green.shade200,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      size: 14,
                                                      color:
                                                          Colors.green.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Aktif',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Colors
                                                                .green
                                                                .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Upload QRIS untuk metode pembayaran QRIS',
                                        ),
                                        const Divider(height: 32),

                                        // Tampilkan QRIS yang sudah diupload
                                        if (user?.qrisImageUrl != null)
                                          Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    // Preview QRIS
                                                    Container(
                                                      width: 200,
                                                      height: 200,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade400,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        child: Image.network(
                                                          user!.qrisImageUrl!,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder: (
                                                            context,
                                                            child,
                                                            loadingProgress,
                                                          ) {
                                                            if (loadingProgress ==
                                                                null)
                                                              return child;
                                                            return Center(
                                                              child: CircularProgressIndicator(
                                                                value:
                                                                    loadingProgress.expectedTotalBytes !=
                                                                            null
                                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                                            loadingProgress.expectedTotalBytes!
                                                                        : null,
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder: (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Container(
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade200,
                                                              child: const Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .error_outline,
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                    size: 40,
                                                                  ),
                                                                  SizedBox(
                                                                    height: 8,
                                                                  ),
                                                                  Text(
                                                                    'Gagal memuat QRIS',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color:
                                                                          Colors
                                                                              .grey,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    // Info QRIS
                                                    if (user.qrisBankName !=
                                                            null ||
                                                        user.qrisAccountName !=
                                                            null)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors
                                                                  .blue
                                                                  .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            if (user.qrisBankName !=
                                                                null)
                                                              Text(
                                                                'Bank/E-Wallet: ${user.qrisBankName!}',
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color:
                                                                      Colors
                                                                          .blue,
                                                                ),
                                                              ),
                                                            if (user.qrisAccountName !=
                                                                null)
                                                              Text(
                                                                'Pemilik: ${user.qrisAccountName!}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      Colors
                                                                          .blue
                                                                          .shade700,
                                                                ),
                                                              ),
                                                            if (user.qrisUpdatedAt !=
                                                                null)
                                                              Text(
                                                                'Diupdate: ${_formatDate(user.qrisUpdatedAt!)}',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color:
                                                                      Colors
                                                                          .grey
                                                                          .shade600,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              // Tombol Action QRIS
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed:
                                                          _uploadQrisImage,
                                                      icon: const Icon(
                                                        Icons.change_circle,
                                                      ),
                                                      label: const Text(
                                                        'Ganti QRIS',
                                                      ),
                                                      style:
                                                          OutlinedButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.blue,
                                                            side:
                                                                const BorderSide(
                                                                  color:
                                                                      Colors
                                                                          .blue,
                                                                ),
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () async {
                                                        // Test QRIS
                                                        await _testQrisScan(
                                                          user.qrisImageUrl!,
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        Icons.qr_code_scanner,
                                                      ),
                                                      label: const Text(
                                                        'Test Scan',
                                                      ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.green,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        else
                                          // QRIS Belum Diupload
                                          Column(
                                            children: [
                                              Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.qr_code_scanner_rounded,
                                                  size: 60,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Belum ada QRIS diupload',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Upload QRIS dari e-wallet atau mobile banking Anda untuk menggunakan metode pembayaran QRIS',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              ElevatedButton.icon(
                                                onPressed: _uploadQrisImage,
                                                icon: const Icon(Icons.upload),
                                                label: const Text(
                                                  'Upload QRIS',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  minimumSize:
                                                      const Size.fromHeight(48),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Format: JPG, PNG, atau GIF • Maks. 5MB',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Pengaturan Toko Card
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Pengaturan Toko',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('Atur informasi toko Anda'),
                                        const Divider(height: 32),

                                        // Nama Toko
                                        const Text(
                                          'Nama Toko',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _storeNameController,
                                          decoration: InputDecoration(
                                            hintText: 'Masukkan nama toko',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Alamat Toko
                                        const Text(
                                          'Alamat Toko',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _storeAddressController,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Masukkan alamat lengkap toko',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Telepon Toko
                                        const Text(
                                          'Telepon Toko',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _storePhoneController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Masukkan nomor telepon toko',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          keyboardType: TextInputType.phone,
                                        ),

                                        const SizedBox(height: 16),

                                        // Footer Struk
                                        const Text(
                                          'Footer Struk',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _receiptFooterController,
                                          maxLines: 2,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Contoh: Terima kasih sudah berbelanja',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // Tombol Simpan Pengaturan
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            onPressed: _saveStoreSettings,
                                            icon: const Icon(Icons.save),
                                            label: const Text(
                                              'Simpan Pengaturan',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Right Column - Pengaturan Lainnya
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                // Detail Akun Card
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Detail Akun',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Informasi tentang akun Anda',
                                        ),
                                        const SizedBox(height: 16),
                                        detailRow(
                                          'Status',
                                          'Aktif',
                                          Colors.green,
                                        ),
                                        detailRow('Peran', 'Admin', null),
                                        detailRow(
                                          'Bergabung Sejak',
                                          _formatDate(DateTime.now()),
                                          null,
                                        ),
                                        const SizedBox(height: 16),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            onPressed: _showEditProfileDialog,
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 18,
                                            ),
                                            label: const Text('Edit Profil'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF3B82F6,
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Keamanan Card
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Keamanan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Kelola keamanan akun'),
                                        const SizedBox(height: 16),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          title: const Text('Ubah Kata Sandi'),
                                          subtitle: const Text(
                                            'Perbarui kata sandi Anda',
                                          ),
                                          trailing: OutlinedButton(
                                            onPressed: () {
                                              // Navigasi ke halaman ubah password
                                            },
                                            child: const Text('Ubah'),
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.fingerprint,
                                          ),
                                          title: const Text('Biometric Login'),
                                          subtitle: const Text(
                                            'Aktifkan login sidik jari',
                                          ),
                                          trailing: Switch(
                                            value: false,
                                            onChanged: (value) {},
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.notifications_active,
                                          ),
                                          title: const Text(
                                            'Notifikasi Transaksi',
                                          ),
                                          subtitle: const Text(
                                            'Dapatkan notifikasi transaksi baru',
                                          ),
                                          trailing: Switch(
                                            value: true,
                                            onChanged: (value) {},
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Ekspor Data Card
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ekspor Data',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Unduh data toko Anda'),
                                        const SizedBox(height: 16),
                                        _buildExportTile(
                                          Icons.description,
                                          'Laporan Harian',
                                          'Export data transaksi harian',
                                        ),
                                        _buildExportTile(
                                          Icons.inventory,
                                          'Data Menu',
                                          'Export katalog menu',
                                        ),
                                        _buildExportTile(
                                          Icons.analytics,
                                          'Statistik',
                                          'Export data statistik penjualan',
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _exportAllData();
                                          },
                                          icon: const Icon(Icons.download),
                                          label: const Text(
                                            'Export Semua Data',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size.fromHeight(
                                              40,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Logout Card
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Keluar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Keluar dari akun Anda'),
                                        const SizedBox(height: 16),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            _confirmLogout();
                                          },
                                          icon: const Icon(Icons.logout),
                                          label: const Text('Logout'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                            minimumSize: const Size.fromHeight(
                                              40,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'KasirPro v1.0.0',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          '© 2024 KasirPro Team',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget detailRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.download, size: 20),
        onPressed: () {},
        tooltip: 'Download',
      ),
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(vertical: -3),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _testQrisScan(String qrisUrl) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Test Scan QRIS'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(qrisUrl, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Coba scan QRIS ini dengan aplikasi e-wallet atau mobile banking Anda',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Panggil logout function dari provider
                  Provider.of<UserProfileProvider>(
                    context,
                    listen: false,
                  ).logout();
                  // Navigasi ke login screen
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  void _exportAllData() {
    // Implementasi export data
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Export Data'),
            content: const Text(
              'Fitur export data akan segera tersedia dalam update berikutnya.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _receiptFooterController.dispose();
    _qrisBankController.dispose();
    _qrisAccountController.dispose();
    super.dispose();
  }
}
