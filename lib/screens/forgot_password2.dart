import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kasir_pro/screens/forgot_password3.dart';

class ForgotPassword2Screen extends StatefulWidget {
  final String email;

  const ForgotPassword2Screen({Key? key, required this.email})
    : super(key: key);

  @override
  State<ForgotPassword2Screen> createState() => _ForgotPassword2State();
}

class _ForgotPassword2State extends State<ForgotPassword2Screen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  bool _isVerifying = false;

  Future<void> _verifyOTP() async {
    String inputOtp = _otpControllers.map((c) => c.text.trim()).join();

    if (inputOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan kode OTP lengkap")),
      );
      return;
    }

    try {
      setState(() => _isVerifying = true);

      final doc =
          await FirebaseFirestore.instance
              .collection('otp_reset_codes')
              .doc(widget.email)
              .get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kode OTP tidak ditemukan.")),
        );
        return;
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] ?? '';
      final createdAt = (data['createdAt'] as Timestamp).toDate();

      // Periksa apakah OTP kadaluarsa (>5 menit)
      final expiryTime = createdAt.add(const Duration(minutes: 5));
      if (DateTime.now().isAfter(expiryTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kode OTP telah kadaluarsa.")),
        );
        return;
      }

      // Verifikasi OTP
      if (inputOtp == storedOtp) {
        // Hapus OTP dari Firestore setelah verifikasi
        await FirebaseFirestore.instance
            .collection('otp_reset_codes')
            .doc(widget.email)
            .delete();

        // Pindah ke halaman reset password (forgot_password3)
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPassword3Screen(email: widget.email),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Kode OTP tidak valid.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text("Kembali", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildStepIndicator(),
              const SizedBox(height: 30),
              const Text(
                "Verifikasi OTP",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Masukkan kode OTP yang telah dikirim ke email\n${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: 45,
                    height: 55,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextField(
                      controller: _otpControllers[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F9BEA),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      _isVerifying
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            "Verifikasi",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("Tidak menerima kode? "),
                  Text(
                    "Kirim ulang",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle("1", true),
        _buildLine(),
        _buildStepCircle("2", true),
        _buildLine(),
        _buildStepCircle("3", false),
      ],
    );
  }

  Widget _buildStepCircle(String number, bool active) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: active ? Colors.blue : Colors.grey.shade300,
      child: Text(
        number,
        style: TextStyle(
          color: active ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLine() {
    return Container(height: 2, width: 40, color: Colors.blue);
  }
}
