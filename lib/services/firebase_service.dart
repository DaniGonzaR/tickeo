import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tickeo/models/bill.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Local storage keys
  static const String _billsKey = 'tickeo_bills';

  // Save bill to local storage (simulating Firestore)
  Future<void> saveBill(Bill bill) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final billsJson = prefs.getString(_billsKey) ?? '[]';
      final bills = List<Map<String, dynamic>>.from(jsonDecode(billsJson));
      
      // Remove existing bill with same ID if it exists
      bills.removeWhere((b) => b['id'] == bill.id);
      
      // Add the new/updated bill
      bills.add(bill.toJson());
      
      await prefs.setString(_billsKey, jsonEncode(bills));
    } catch (e) {
      throw Exception('Error guardando la cuenta: $e');
    }
  }

  // Get bill by ID from local storage
  Future<Bill?> getBill(String billId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final billsJson = prefs.getString(_billsKey) ?? '[]';
      final bills = List<Map<String, dynamic>>.from(jsonDecode(billsJson));
      
      final billData = bills.firstWhere(
        (b) => b['id'] == billId,
        orElse: () => <String, dynamic>{},
      );
      
      if (billData.isNotEmpty) {
        return Bill.fromJson(billData);
      }
      return null;
    } catch (e) {
      throw Exception('Error obteniendo la cuenta: $e');
    }
  }

  // Get bill by share code from local storage
  Future<Bill?> getBillByShareCode(String shareCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final billsJson = prefs.getString(_billsKey) ?? '[]';
      final bills = List<Map<String, dynamic>>.from(jsonDecode(billsJson));
      
      final billData = bills.firstWhere(
        (b) => b['shareCode'] == shareCode,
        orElse: () => <String, dynamic>{},
      );
      
      if (billData.isNotEmpty) {
        return Bill.fromJson(billData);
      }
      return null;
    } catch (e) {
      throw Exception('Error buscando la cuenta: $e');
    }
  }

  // Update bill in local storage
  Future<void> updateBill(Bill bill) async {
    try {
      await saveBill(bill); // Same as save for local storage
    } catch (e) {
      throw Exception('Error actualizando la cuenta: $e');
    }
  }

  // Delete bill from local storage
  Future<void> deleteBill(String billId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final billsJson = prefs.getString(_billsKey) ?? '[]';
      final bills = List<Map<String, dynamic>>.from(jsonDecode(billsJson));
      
      bills.removeWhere((b) => b['id'] == billId);
      
      await prefs.setString(_billsKey, jsonEncode(bills));
    } catch (e) {
      throw Exception('Error eliminando la cuenta: $e');
    }
  }

  // Get user's bills from local storage (simulating authenticated user bills)
  Future<List<Bill>> getUserBills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final billsJson = prefs.getString(_billsKey) ?? '[]';
      final bills = List<Map<String, dynamic>>.from(jsonDecode(billsJson));
      
      return bills
          .map((billData) => Bill.fromJson(billData))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      throw Exception('Error obteniendo cuentas del usuario: $e');
    }
  }

  // Get all bills from local storage
  Future<List<Bill>> getAllBills() async {
    try {
      return await getUserBills(); // Same for offline mode
    } catch (e) {
      throw Exception('Error obteniendo todas las cuentas: $e');
    }
  }

  // Clear all bills from local storage
  Future<void> clearAllBills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_billsKey);
    } catch (e) {
      throw Exception('Error limpiando cuentas: $e');
    }
  }

  // Get bills count
  Future<int> getBillsCount() async {
    try {
      final bills = await getUserBills();
      return bills.length;
    } catch (e) {
      return 0;
    }
  }

  // Check if service is available (always true for offline mode)
  Future<bool> isServiceAvailable() async {
    return true;
  }
}
