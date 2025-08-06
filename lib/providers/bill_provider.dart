import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tickeo/models/bill.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/payment.dart';
import 'package:tickeo/services/ocr_service.dart';
import 'package:tickeo/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

class BillProvider extends ChangeNotifier {
  final OCRService _ocrService = OCRService();
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  Bill? _currentBill;
  final List<Bill> _billHistory = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Bill? get currentBill => _currentBill;
  List<Bill> get billHistory => _billHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create new bill from OCR
  Future<void> createBillFromImage(File imageFile, String billName) async {
    _setLoading(true);
    _clearError();

    try {
      final ocrResult = await _ocrService.processReceiptImage(imageFile);

      final bill = Bill(
        id: _uuid.v4(),
        name: billName,
        createdAt: DateTime.now(),
        items: ocrResult['items'] as List<BillItem>,
        subtotal: ocrResult['subtotal'] as double,
        tax: ocrResult['tax'] as double,
        tip: 0.0,
        total: ocrResult['total'] as double,
        participants: [],
        payments: [],
        restaurantName: ocrResult['restaurantName'] as String?,
        shareCode: _generateShareCode(),
      );

      _currentBill = bill;
      await _saveBillLocally(bill);
      notifyListeners();
    } catch (e) {
      _setError('Error procesando la imagen: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create manual bill
  void createManualBill(String billName) {
    final bill = Bill(
      id: _uuid.v4(),
      name: billName,
      createdAt: DateTime.now(),
      items: [],
      subtotal: 0.0,
      tax: 0.0,
      tip: 0.0,
      total: 0.0,
      participants: [],
      payments: [],
      shareCode: _generateShareCode(),
    );

    _currentBill = bill;
    notifyListeners();
  }

  // Add participant
  void addParticipant(String participantName) {
    if (_currentBill == null) return;

    final participantId = _uuid.v4();
    final updatedParticipants = [..._currentBill!.participants, participantId];

    // Create payment entry for new participant
    final payment = Payment(
      id: _uuid.v4(),
      participantId: participantId,
      participantName: participantName,
      amount: 0.0,
      method: PaymentMethod.cash,
    );

    _currentBill = _currentBill!.copyWith(
      participants: updatedParticipants,
      payments: [..._currentBill!.payments, payment],
    );

    _updatePaymentAmounts();
    notifyListeners();
  }

  // Remove participant
  void removeParticipant(String participantId) {
    if (_currentBill == null) return;

    // Remove participant from all items
    final updatedItems = _currentBill!.items.map((item) {
      final updatedSelectedBy =
          item.selectedBy.where((id) => id != participantId).toList();
      return item.copyWith(selectedBy: updatedSelectedBy);
    }).toList();

    // Remove participant and their payment
    final updatedParticipants =
        _currentBill!.participants.where((id) => id != participantId).toList();
    final updatedPayments = _currentBill!.payments
        .where((payment) => payment.participantId != participantId)
        .toList();

    _currentBill = _currentBill!.copyWith(
      participants: updatedParticipants,
      payments: updatedPayments,
      items: updatedItems,
    );

    _updatePaymentAmounts();
    notifyListeners();
  }

  // Toggle item selection for participant
  void toggleItemSelection(String itemId, String participantId) {
    if (_currentBill == null) return;

    final updatedItems = _currentBill!.items.map((item) {
      if (item.id == itemId) {
        final updatedSelectedBy = item.selectedBy.contains(participantId)
            ? item.selectedBy.where((id) => id != participantId).toList()
            : [...item.selectedBy, participantId];
        return item.copyWith(selectedBy: updatedSelectedBy);
      }
      return item;
    }).toList();

    _currentBill = _currentBill!.copyWith(items: updatedItems);
    _updatePaymentAmounts();
    notifyListeners();
  }

  // Add manual item
  void addManualItem(String itemName, double price, int quantity) {
    if (_currentBill == null) return;

    final item = BillItem(
      id: _uuid.v4(),
      name: itemName,
      price: price,
      quantity: quantity,
      selectedBy: [],
    );

    final updatedItems = [..._currentBill!.items, item];
    final newSubtotal =
        updatedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final newTotal = newSubtotal + _currentBill!.tax + _currentBill!.tip;

    _currentBill = _currentBill!.copyWith(
      items: updatedItems,
      subtotal: newSubtotal,
      total: newTotal,
    );

    _updatePaymentAmounts();
    notifyListeners();
  }

  // Update tip
  void updateTip(double tip) {
    if (_currentBill == null) return;

    final newTotal = _currentBill!.subtotal + _currentBill!.tax + tip;
    _currentBill = _currentBill!.copyWith(
      tip: tip,
      total: newTotal,
    );

    _updatePaymentAmounts();
    notifyListeners();
  }

  // Split bill equally
  void splitBillEqually() {
    if (_currentBill == null || _currentBill!.participants.isEmpty) return;

    final amountPerPerson =
        _currentBill!.total / _currentBill!.participants.length;

    final updatedPayments = _currentBill!.payments.map((payment) {
      return payment.copyWith(amount: amountPerPerson);
    }).toList();

    _currentBill = _currentBill!.copyWith(payments: updatedPayments);
    notifyListeners();
  }

  // Mark payment as paid
  void markPaymentAsPaid(
      String participantId, PaymentMethod method, String? notes) {
    if (_currentBill == null) return;

    final updatedPayments = _currentBill!.payments.map((payment) {
      if (payment.participantId == participantId) {
        return payment.copyWith(
          isPaid: true,
          paidAt: DateTime.now(),
          method: method,
          notes: notes,
        );
      }
      return payment;
    }).toList();

    _currentBill = _currentBill!.copyWith(payments: updatedPayments);

    // Check if bill is completed
    final allPaid = updatedPayments.every((payment) => payment.isPaid);
    if (allPaid) {
      _currentBill = _currentBill!.copyWith(isCompleted: true);
    }

    notifyListeners();
  }

  // Save bill to Firebase
  Future<void> saveBillToCloud() async {
    if (_currentBill == null) return;

    _setLoading(true);
    try {
      await _firebaseService.saveBill(_currentBill!);
    } catch (e) {
      _setError('Error guardando en la nube: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load bill from share code
  Future<void> loadBillFromShareCode(String shareCode) async {
    _setLoading(true);
    _clearError();

    try {
      final bill = await _firebaseService.getBillByShareCode(shareCode);
      if (bill != null) {
        _currentBill = bill;
        notifyListeners();
      } else {
        _setError('No se encontró la cuenta con ese código');
      }
    } catch (e) {
      _setError('Error cargando la cuenta: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  void _updatePaymentAmounts() {
    if (_currentBill == null) return;

    final updatedPayments = _currentBill!.payments.map((payment) {
      final amount =
          _currentBill!.getAmountForParticipant(payment.participantId);
      return payment.copyWith(amount: amount);
    }).toList();

    _currentBill = _currentBill!.copyWith(payments: updatedPayments);
  }

  String _generateShareCode() {
    return _uuid.v4().substring(0, 8).toUpperCase();
  }

  Future<void> _saveBillLocally(Bill bill) async {
    // Implementation for local storage
    _billHistory.add(bill);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  String getParticipantName(String participantId) {
    final payment = _currentBill?.payments.firstWhere(
      (p) => p.participantId == participantId,
      orElse: () => Payment(
        id: '',
        participantId: participantId,
        participantName: 'Usuario',
        amount: 0.0,
        method: PaymentMethod.cash,
      ),
    );
    return payment?.participantName ?? 'Usuario';
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
