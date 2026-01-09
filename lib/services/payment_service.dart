import 'dart:async';
import 'dart:convert';
import 'dart:math';

class PaymentService {
  static const bool _useSimulation = true; // Selalu true untuk sekarang

  /// Create QRIS transaction - SELALU simulation mode
  static Future<Map<String, dynamic>> createQrisTransaction({
    required String orderId,
    required int amount,
    required String customerName,
  }) async {
    return await _simulateQrisTransaction(
      orderId: orderId,
      amount: amount,
      customerName: customerName,
    );
  }

  /// Check transaction status dengan simulation yang realistis
  static Future<Map<String, dynamic>> checkTransactionStatus(
    String orderId,
  ) async {
    return await _simulateStatusCheck(orderId);
  }

  /// Simulation QRIS transaction
  static Future<Map<String, dynamic>> _simulateQrisTransaction({
    required String orderId,
    required int amount,
    required String customerName,
  }) async {
    // Simulasi delay seperti real API call
    await Future.delayed(const Duration(seconds: 2));

    final qrData = _generateSimulationQrData(orderId, amount);

    return {
      'status': 'success',
      'transaction_id': 'TRX${DateTime.now().millisecondsSinceEpoch}',
      'order_id': orderId,
      'qr_data': qrData,
      'gross_amount': amount,
      'transaction_status': 'pending', // SELALU mulai dengan pending
      'payment_type': 'qris',
      'is_simulation': true,
      'message': 'Scan QR code untuk melakukan pembayaran',
    };
  }

  /// Simulation status check dengan probability yang realistis
  static Future<Map<String, dynamic>> _simulateStatusCheck(
    String orderId,
  ) async {
    // Simulasi network delay
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    final randomValue = random.nextDouble();

    String status;
    String message;

    if (randomValue < 0.3) {
      // 30% chance pembayaran berhasil
      status = 'settlement';
      message = '✅ Pembayaran berhasil';
    } else if (randomValue < 0.6) {
      // 30% chance masih pending
      status = 'pending';
      message = '⏳ Menunggu pembayaran...';
    } else if (randomValue < 0.8) {
      // 20% chance expired
      status = 'expire';
      message = '⏰ Waktu pembayaran habis';
    } else {
      // 20% chance failed
      status = 'deny';
      message = '❌ Pembayaran ditolak';
    }

    return {
      'status': 'success',
      'transaction_status': status,
      'order_id': orderId,
      'message': message,
      'is_simulation': true,
    };
  }

  /// Generate simulation QR data yang bisa discan (format dummy)
  static String _generateSimulationQrData(String orderId, int amount) {
    // Format QRIS simulation yang aman
    return 'SIMULATION-MODE|Order:$orderId|Amount:$amount|KasirPro|${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate static QRIS payload untuk compatibility
  static String generateStaticQrisPayload({
    required String orderId,
    required int amount,
    required String merchantName,
  }) {
    final payload = {
      '00': '01',
      '01': '12',
      '52': '1520',
      '53': '360',
      '54': amount.toString(),
      '58': 'ID',
      '59': merchantName,
      '60': 'JAKARTA',
    };

    final payloadString =
        payload.entries
            .map(
              (entry) =>
                  '${entry.key}${entry.value.length.toString().padLeft(2, '0')}${entry.value}',
            )
            .join();

    final crc = _generateCRC(payloadString);
    return '$payloadString' + '6304' + '$crc';
  }

  static String _generateCRC(String data) {
    final dataForCrc = data + '6304';
    final bytes = utf8.encode(dataForCrc);
    final crc = _calculateCRC16(bytes);
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static int _calculateCRC16(List<int> bytes) {
    int crc = 0xFFFF;
    for (final byte in bytes) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) == 1) {
          crc = (crc >> 1) ^ 0x8408;
        } else {
          crc = crc >> 1;
        }
      }
    }
    return crc ^ 0xFFFF;
  }
}
