import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Comentado temporalmente
import 'package:tickeo/models/bill.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _billsCollection = 'bills';
  static const String _usersCollection = 'users';

  // Save bill to Firestore
  Future<void> saveBill(Bill bill) async {
    try {
      await _firestore
          .collection(_billsCollection)
          .doc(bill.id)
          .set(bill.toJson());
    } catch (e) {
      throw Exception('Error guardando la cuenta: $e');
    }
  }

  // Get bill by ID
  Future<Bill?> getBill(String billId) async {
    try {
      final doc =
          await _firestore.collection(_billsCollection).doc(billId).get();

      if (doc.exists && doc.data() != null) {
        return Bill.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Error obteniendo la cuenta: $e');
    }
  }

  // Get bill by share code
  Future<Bill?> getBillByShareCode(String shareCode) async {
    try {
      final querySnapshot = await _firestore
          .collection(_billsCollection)
          .where('shareCode', isEqualTo: shareCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Bill.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Error buscando la cuenta: $e');
    }
  }

  // Update bill
  Future<void> updateBill(Bill bill) async {
    try {
      await _firestore
          .collection(_billsCollection)
          .doc(bill.id)
          .update(bill.toJson());
    } catch (e) {
      throw Exception('Error actualizando la cuenta: $e');
    }
  }

  // Delete bill
  Future<void> deleteBill(String billId) async {
    try {
      await _firestore.collection(_billsCollection).doc(billId).delete();
    } catch (e) {
      throw Exception('Error eliminando la cuenta: $e');
    }
  }

  // Get user's bills (requires authentication)
  Future<List<Bill>> getUserBills() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final querySnapshot = await _firestore
          .collection(_billsCollection)
          .where('createdBy', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Bill.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo las cuentas del usuario: $e');
    }
  }

  // Listen to bill changes in real-time
  Stream<Bill?> listenToBill(String billId) {
    return _firestore
        .collection(_billsCollection)
        .doc(billId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Bill.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // Anonymous sign in (for users without account)
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      throw Exception('Error en autenticación anónima: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Error en inicio de sesión: $e');
    }
  }

  // Create account with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Error creando cuenta: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error cerrando sesión: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Save user profile
  Future<void> saveUserProfile(Map<String, dynamic> userData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection(_usersCollection).doc(user.uid).set({
        ...userData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error guardando perfil: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(user.uid).get();

      return doc.data();
    } catch (e) {
      throw Exception('Error obteniendo perfil: $e');
    }
  }

  // Batch operations for better performance
  Future<void> saveBillsBatch(List<Bill> bills) async {
    final batch = _firestore.batch();

    for (final bill in bills) {
      final docRef = _firestore.collection(_billsCollection).doc(bill.id);
      batch.set(docRef, bill.toJson());
    }

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Error guardando cuentas en lote: $e');
    }
  }
}
