// ============================================================
// ملف: services/auth_service.dart
// الوظيفة: خدمة المصادقة مع Firestore
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AuthResult> login(String email, String password) async {
    try {
      // 1. تسجيل الدخول في Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. جلب بيانات المستخدم من Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return AuthResult.failure('بيانات المستخدم غير موجودة');
      }

      // 3. تحويل البيانات إلى UserModel
      final userModel = UserModel.fromFirestore(
        userDoc.data()!,
        userCredential.user!.uid,
      );

      // 4. التحقق من أن الحساب نشط
      if (!userModel.isActive) {
        await _auth.signOut();
        return AuthResult.failure('هذا الحساب غير نشط، يرجى التواصل مع الإدارة');
      }

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'المستخدم غير موجود';
          break;
        case 'wrong-password':
          message = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صالح';
          break;
        case 'user-disabled':
          message = 'هذا الحساب معطل';
          break;
        default:
          message = 'حدث خطأ: ${e.message}';
      }
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('حدث خطأ: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // دالة لتسجيل مستخدم جديد (اختياري)
  Future<AuthResult> register(UserModel user, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      final userWithId = user.copyWith(uid: userCredential.user!.uid);
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userWithId.toFirestore());

      return AuthResult.success(userWithId);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(e.message ?? 'حدث خطأ');
    } catch (e) {
      return AuthResult.failure('حدث خطأ: ${e.toString()}');
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? errorMessage;

  AuthResult.success(this.user)
      : isSuccess = true,
        errorMessage = null;

  AuthResult.failure(this.errorMessage)
      : isSuccess = false,
        user = null;
}