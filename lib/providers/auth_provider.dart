import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/analytics_service.dart';

class AuthProvider with ChangeNotifier {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AnalyticsService _analytics = AnalyticsService();
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final storedUid = await _storage.read(key: 'uid');
      
      _auth.authStateChanges().listen((firebase.User? firebaseUser) async {
        if (firebaseUser != null) {
          await _storage.write(key: 'uid', value: firebaseUser.uid);
          _user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'User',
            photoURL: firebaseUser.photoURL,
            role: 'user',
            createdAt: DateTime.now(),
          );
        } else {
          _user = null;
          if (storedUid != null) {
            await _storage.delete(key: 'uid');
          }
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      print('Starting Google Sign In process...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('Google Sign In result: ${googleUser?.email}');

      if (googleUser == null) {
        print('Google Sign In was cancelled by user');
        throw Exception('Google Sign In was cancelled');
      }

      // Obtain the auth details from the request
      print('Getting Google auth details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Got Google auth details');

      // Create a new credential
      print('Creating Firebase credential...');
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      print('Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      print('Firebase sign in result: ${userCredential.user?.email}');
      
      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        print('Storing user ID in secure storage...');
        await _storage.write(key: 'uid', value: firebaseUser.uid);
        
        // Обновляем состояние пользователя
        print('Updating user state...');
        _user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? 'User',
          photoURL: firebaseUser.photoURL,
          role: 'user',
          createdAt: DateTime.now(),
        );
        
        // Логируем успешный вход
        print('Logging analytics...');
        await _analytics.logLogin('google');
        print('Google sign in successful for user: ${_user?.email}');
      } else {
        print('Firebase user is null after sign in');
        throw Exception('Failed to sign in with Google');
      }
    } catch (e, stackTrace) {
      print('Error in Google Sign In: $e');
      print('Stack trace: $stackTrace');
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Проверяем доступные методы входа для email
      final methods = await _auth.fetchSignInMethodsForEmail(email);

      if (methods.isEmpty) {
        throw Exception('No user found with this email');
      }

      // Если email связан только с Google
      if (methods.contains('google.com') && !methods.contains('password')) {
        throw Exception('This email is registered with Google. Please use Google Sign-In.');
      }

      // Пробуем войти с email/password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await _storage.write(key: 'uid', value: userCredential.user!.uid);
        await _analytics.logLogin('email');
      } else {
        throw Exception('Failed to sign in with email');
      }
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Invalid email or password');
      } else {
        throw Exception(e.message ?? 'Failed to sign in');
      }
    } catch (e) {
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Проверяем, не существует ли уже пользователь с таким email
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        if (methods.contains('google.com')) {
          throw Exception('This email is already registered with Google. Please use Google Sign-In.');
        } else {
          throw Exception('This email is already registered. Please sign in instead.');
        }
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await _analytics.logSignUp('email');
      }
    } catch (e) {
      print('Error in sign up: $e');
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        _storage.deleteAll(),
      ]);
      _user = null;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuthState() async {
    try {
      _isLoading = true;
      notifyListeners();

      final storedUid = await _storage.read(key: 'uid');
      final currentUser = _auth.currentUser;
      
      if (currentUser != null && storedUid == currentUser.uid) {
        _user = User(
          id: currentUser.uid,
          email: currentUser.email ?? '',
          name: currentUser.displayName ?? 'User',
          role: 'user',
          createdAt: DateTime.now(),
        );
      } else {
        _user = null;
        await _storage.deleteAll();
      }
    } catch (e) {
      _user = null;
      await _storage.deleteAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 