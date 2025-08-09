import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tickeo/models/bill.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/payment.dart';
import 'package:tickeo/services/ocr_service.dart';
import 'package:tickeo/services/firebase_service.dart';
import 'package:tickeo/utils/error_handler.dart';
import 'package:tickeo/utils/validators.dart';
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
  bool get hasBillsToSync => _billHistory.any((bill) => !bill.isSynced);
  int get unsyncedBillsCount =>
      _billHistory.where((bill) => !bill.isSynced).length;

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
        tax: 0.0,
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

  // Create bill from mock OCR data (web-compatible version)
  Future<void> createBillFromMockOCR(String billName) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate bill name
      final nameValidation = Validators.validateBillName(billName);
      if (nameValidation != null) {
        _setError(nameValidation);
        return;
      }

      // Create basic structure for manual editing (web-compatible)
      final items = [
        BillItem(
          id: const Uuid().v4(),
          name: 'Producto del ticket',
          price: 0.00,
          selectedBy: [],
        )
      ];

      const subtotal = 0.00;
      const tax = 0.0;
      const total = 0.00;

      final bill = Bill(
        id: _uuid.v4(),
        name: billName.trim(),
        createdAt: DateTime.now(),
        items: items,
        subtotal: subtotal,
        tax: tax,
        tip: 0.0,
        total: total,
        participants: [],
        payments: [],
        shareCode: _generateShareCode(),
      );

      _currentBill = bill;
      await _saveBillLocally(bill);
      notifyListeners();
    } catch (e) {
      _setError('Error creando cuenta desde OCR: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create bill from OCR result (camera scanner integration)
  Future<void> createBillFromOCRResult(
      String billName, Map<String, dynamic> ocrResult) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate bill name
      final nameValidation = Validators.validateBillName(billName);
      if (nameValidation != null) {
        _setError(nameValidation);
        return;
      }

      final items = ocrResult['items'] as List<BillItem>;
      final subtotal = ocrResult['subtotal'] as double;
      final total = ocrResult['total'] as double;
      final restaurantName = ocrResult['restaurantName'] as String?;

      final bill = Bill(
        id: _uuid.v4(),
        name: billName.trim(),
        createdAt: DateTime.now(),
        items: items,
        subtotal: subtotal,
        tax: 0.0, // No tax as per requirements
        tip: 0.0, // No tip as per requirements
        total: total,
        participants: [],
        payments: [],
        restaurantName: restaurantName,
        shareCode: _generateShareCode(),
      );

      _currentBill = bill;
      await _saveBillLocally(bill);
      notifyListeners();
    } catch (e) {
      _setError('Error procesando el resultado OCR: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create manual bill with validation
  bool createManualBill(String billName) {
    try {
      _clearError();

      // Validate bill name
      final nameValidation = Validators.validateBillName(billName);
      if (nameValidation != null) {
        _setError(nameValidation);
        return false;
      }

      final bill = Bill(
        id: _uuid.v4(),
        name: billName.trim(),
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
      _saveBillLocally(bill); // Save to history like OCR bills
      notifyListeners();
      return true;
    } catch (e) {
      ErrorHandler.logError('createManualBill', e);
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    }
  }

  // Add participant with validation
  bool addParticipant(String participantName) {
    try {
      if (_currentBill == null) {
        _setError('No active bill to add participant to');
        return false;
      }

      _clearError();

      // Validate participant name
      final nameValidation =
          Validators.validateParticipantName(participantName);
      if (nameValidation != null) {
        _setError(nameValidation);
        return false;
      }

      // Check for duplicate participant names
      final existingNames = _currentBill!.payments
          .map((p) => p.participantName.toLowerCase().trim())
          .toList();

      if (existingNames.contains(participantName.toLowerCase().trim())) {
        _setError('A participant with this name already exists');
        return false;
      }

      // Check participant limit
      if (_currentBill!.participants.length >= 20) {
        _setError('Maximum 20 participants allowed per bill');
        return false;
      }

      final participantId = _uuid.v4();
      final updatedParticipants = [
        ..._currentBill!.participants,
        participantId
      ];

      // Create payment entry for new participant
      final payment = Payment(
        id: _uuid.v4(),
        participantId: participantId,
        participantName: participantName.trim(),
        amount: 0.0,
        method: PaymentMethod.cash,
      );

      _currentBill = _currentBill!.copyWith(
        participants: updatedParticipants,
        payments: [..._currentBill!.payments, payment],
      );

      _updatePaymentAmounts();
      _saveBillLocally(_currentBill!); // Sync changes to history
      notifyListeners();
      return true;
    } catch (e) {
      ErrorHandler.logError('addParticipant', e);
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    }
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

  // Remove item from bill
  void removeItem(String itemId) {
    if (_currentBill == null) return;

    // Check if any payment has been made - if so, don't allow deletion
    if (hasAnyPaymentBeenMade()) {
      _setError(
          'No se pueden eliminar productos una vez que alguien ha pagado');
      return;
    }

    final updatedItems =
        _currentBill!.items.where((item) => item.id != itemId).toList();

    // Recalculate subtotal and total after removing the item
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

  // Check if any payment has been made
  bool hasAnyPaymentBeenMade() {
    if (_currentBill == null) return false;
    return _currentBill!.payments.any((payment) => payment.isPaid);
  }

  // Toggle item selection for participant
  void toggleItemSelection(String itemId, String participantId) {
    if (_currentBill == null) return;

    // Check if any payment has been made - if so, don't allow changes
    if (hasAnyPaymentBeenMade()) {
      _setError(
          'No se pueden modificar las selecciones una vez que alguien ha pagado');
      return;
    }

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

  // Add manual item with validation
  bool addManualItem(String itemName, double price, {int quantity = 1}) {
    try {
      if (_currentBill == null) {
        _setError('No active bill to add item to');
        return false;
      }

      _clearError();

      // Validate item name
      final nameValidation = Validators.validateItemName(itemName);
      if (nameValidation != null) {
        _setError(nameValidation);
        return false;
      }

      // Validate price
      if (price <= 0) {
        _setError('Price must be greater than zero');
        return false;
      }

      if (price > 99999.99) {
        _setError('Price is too high (max: €99,999.99)');
        return false;
      }

      // Validate quantity
      if (quantity <= 0) {
        _setError('Quantity must be greater than zero');
        return false;
      }

      if (quantity > 100) {
        _setError('Maximum quantity is 100');
        return false;
      }

      // Check item limit
      if (_currentBill!.items.length >= 50) {
        _setError('Maximum 50 items allowed per bill');
        return false;
      }

      final item = BillItem(
        id: _uuid.v4(),
        name: itemName.trim(),
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
      _saveBillLocally(_currentBill!); // Sync changes to history
      notifyListeners();
      return true;
    } catch (e) {
      ErrorHandler.logError('addManualItem', e);
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    }
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

    // Check if any payment has been made - if so, don't allow split equally
    if (hasAnyPaymentBeenMade()) {
      _setError(
          'No se puede dividir equitativamente una vez que alguien ha pagado');
      return;
    }

    // Assign all products to all participants for equal split
    final updatedItems = _currentBill!.items.map((item) {
      return item.copyWith(selectedBy: List.from(_currentBill!.participants));
    }).toList();

    final amountPerPerson =
        _currentBill!.total / _currentBill!.participants.length;

    final updatedPayments = _currentBill!.payments.map((payment) {
      return payment.copyWith(amount: amountPerPerson);
    }).toList();

    _currentBill = _currentBill!.copyWith(
      items: updatedItems,
      payments: updatedPayments,
    );

    _saveBillLocally(_currentBill!); // Sync changes to history
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

    // Save changes to history to sync with "Cuentas Recientes"
    _saveBillLocally(_currentBill!);
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

  // Cloud synchronization methods
  Future<void> syncBillsWithCloud() async {
    _setLoading(true);
    _clearError();

    try {
      // Upload unsynced bills to cloud
      final unsyncedBills =
          _billHistory.where((bill) => !bill.isSynced).toList();

      for (final bill in unsyncedBills) {
        await _firebaseService.saveBill(bill);
        // Mark bill as synced
        final index = _billHistory.indexWhere((b) => b.id == bill.id);
        if (index != -1) {
          _billHistory[index] = bill.copyWith(isSynced: true);
        }
      }

      // Download bills from cloud that aren't in local storage
      final cloudBills = await _firebaseService.getUserBills();

      for (final cloudBill in cloudBills) {
        final existsLocally =
            _billHistory.any((bill) => bill.id == cloudBill.id);
        if (!existsLocally) {
          _billHistory.add(cloudBill.copyWith(isSynced: true));
        }
      }

      // Sort bills by creation date (newest first)
      _billHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      notifyListeners();
    } catch (e) {
      _setError('Error sincronizando con la nube: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadBillToCloud(Bill bill) async {
    try {
      await _firebaseService.saveBill(bill);

      // Mark bill as synced in local storage
      final index = _billHistory.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        _billHistory[index] = bill.copyWith(isSynced: true);
        notifyListeners();
      }
    } catch (e) {
      _setError('Error subiendo factura a la nube: ${e.toString()}');
    }
  }

  Future<void> downloadBillsFromCloud() async {
    _setLoading(true);
    _clearError();

    try {
      final cloudBills = await _firebaseService.getUserBills();

      // Replace local bills with cloud bills (cloud is source of truth)
      _billHistory.clear();
      _billHistory
          .addAll(cloudBills.map((bill) => bill.copyWith(isSynced: true)));

      // Sort bills by creation date (newest first)
      _billHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      notifyListeners();
    } catch (e) {
      _setError('Error descargando facturas de la nube: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void markAllBillsAsUnsynced() {
    for (int i = 0; i < _billHistory.length; i++) {
      _billHistory[i] = _billHistory[i].copyWith(isSynced: false);
    }
    notifyListeners();
  }

  void clearLocalData() {
    _billHistory.clear();
    _currentBill = null;
    _clearError();
    notifyListeners();
  }

  String _generateShareCode() {
    return _uuid.v4().substring(0, 8).toUpperCase();
  }

  // Toggle participant for item (alias for toggleItemSelection)
  void toggleParticipantForItem(String itemId, String participantId) {
    toggleItemSelection(itemId, participantId);
  }

  // Toggle payment status for a payment
  void togglePaymentStatus(String paymentId) {
    if (_currentBill == null) return;

    final updatedPayments = _currentBill!.payments.map((payment) {
      if (payment.id == paymentId) {
        return payment.copyWith(isPaid: !payment.isPaid);
      }
      return payment;
    }).toList();

    _currentBill = _currentBill!.copyWith(payments: updatedPayments);
    notifyListeners();
  }

  Future<void> _saveBillLocally(Bill bill) async {
    // Check if bill already exists in history and update it, otherwise add new
    final existingIndex = _billHistory.indexWhere((b) => b.id == bill.id);
    if (existingIndex != -1) {
      // Update existing bill in history
      _billHistory[existingIndex] = bill;
    } else {
      // Add new bill to history
      _billHistory.add(bill);
    }
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
