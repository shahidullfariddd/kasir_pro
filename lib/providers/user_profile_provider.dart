// lib/providers/user_profile_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProfile {
  String? uid;
  String? name;
  String? email;
  String? phone;
  String? photoUrl;

  // QRIS data
  String? qrisImageUrl;
  String? qrisBankName;
  String? qrisAccountName;
  DateTime? qrisUpdatedAt;

  UserProfile({
    this.uid,
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.qrisImageUrl,
    this.qrisBankName,
    this.qrisAccountName,
    this.qrisUpdatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      qrisImageUrl: data['qrisImageUrl'],
      qrisBankName: data['qrisBankName'],
      qrisAccountName: data['qrisAccountName'],
      qrisUpdatedAt:
          data['qrisUpdatedAt'] != null
              ? (data['qrisUpdatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'qrisImageUrl': qrisImageUrl,
      'qrisBankName': qrisBankName,
      'qrisAccountName': qrisAccountName,
      'qrisUpdatedAt':
          qrisUpdatedAt != null ? Timestamp.fromDate(qrisUpdatedAt!) : null,
    };
  }
}

class UserProfileProvider with ChangeNotifier {
  UserProfile? _userProfile;
  User? _firebaseUser;

  UserProfile? get userProfile => _userProfile;
  User? get firebaseUser => _firebaseUser;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserProfileProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _firebaseUser = _auth.currentUser;
    if (_firebaseUser != null) {
      await _fetchUserProfile(_firebaseUser!.uid);
    }
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromFirestore(doc);
      } else {
        // Create user profile if doesn't exist
        _userProfile = UserProfile(
          uid: uid,
          name: _firebaseUser?.displayName,
          email: _firebaseUser?.email,
          photoUrl: _firebaseUser?.photoURL,
        );
        await _saveUserProfile();
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _saveUserProfile() async {
    if (_userProfile == null || _userProfile!.uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userProfile!.uid)
          .set(_userProfile!.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    if (_userProfile == null) return;

    _userProfile = _userProfile!.copyWith(
      name: name ?? _userProfile!.name,
      phone: phone ?? _userProfile!.phone,
    );

    await _saveUserProfile();
    notifyListeners();
  }

  Future<void> updateQris({
    required String imageUrl,
    String? bankName,
    String? accountName,
  }) async {
    if (_userProfile == null) return;

    _userProfile = _userProfile!.copyWith(
      qrisImageUrl: imageUrl,
      qrisBankName: bankName,
      qrisAccountName: accountName,
      qrisUpdatedAt: DateTime.now(),
    );

    await _saveUserProfile();
    notifyListeners();
  }

  Future<void> clearQris() async {
    if (_userProfile == null) return;

    _userProfile = _userProfile!.copyWith(
      qrisImageUrl: null,
      qrisBankName: null,
      qrisAccountName: null,
      qrisUpdatedAt: null,
    );

    await _saveUserProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _userProfile = null;
    _firebaseUser = null;
    notifyListeners();
  }
}

// Extension for copyWith method
extension UserProfileCopyWith on UserProfile {
  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? qrisImageUrl,
    String? qrisBankName,
    String? qrisAccountName,
    DateTime? qrisUpdatedAt,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      qrisImageUrl: qrisImageUrl ?? this.qrisImageUrl,
      qrisBankName: qrisBankName ?? this.qrisBankName,
      qrisAccountName: qrisAccountName ?? this.qrisAccountName,
      qrisUpdatedAt: qrisUpdatedAt ?? this.qrisUpdatedAt,
    );
  }
}
