import 'dart:async';
import 'dart:io';
import 'package:english_words/english_words.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingNotifier extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  var _status = Status.Unauthenticated;
  final _firestore = FirebaseFirestore.instance;
  List<String> saved = <String>[];
  final _suggestions = <WordPair>[];
  User? _user;
  bool isPosEnable = false;
  DocumentReference? docRef;
  final _biggerFont = const TextStyle(fontSize: 18, color: Colors.black);

  SettingNotifier() {
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        status = Status.Unauthenticated;
        user = null;
      } else {
        status = Status.Authenticated;
        user = firebaseUser;
      }
      notifyListeners();
    });
  }

  get suggestions => _suggestions;

  set suggestions(value) {
    _suggestions.addAll(value);
    notifyListeners();
  }

  Widget listBuilder() => ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, i) {
        if (i.isOdd) return const Divider();
        final index = i ~/ 2;
        if (index >= _suggestions.length) {
          _suggestions.addAll(generateWordPairs().take(100));
        }
        final alreadySaved = saved.contains(_suggestions[index].asPascalCase);
        return ListTile(
          title: Text(
            _suggestions[index].asPascalCase,
            style: _biggerFont,
          ),
          trailing: Icon(
            alreadySaved ? Icons.favorite : Icons.favorite_border,
            color: alreadySaved ? Colors.red : null,
            semanticLabel: alreadySaved ? "Remove from saved" : "Save",
          ),
          onTap: () {
            if (alreadySaved) {
              saved.remove(_suggestions[index].asPascalCase);
            } else {
              saved.add(_suggestions[index].asPascalCase);
            }
            notifyListeners();

          },
        );
      });

  Future<UserCredential?> singUp(
      String email, String password, BuildContext ctx) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      final user = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      addUser(email, password, saved);
      return user;
    } on FirebaseAuthException catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
    }
    return null;
  }

  Future<bool> signIn(String email, String password, BuildContext ctx) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      List<String> userSaved = List<String>.from(await getSaved());
      saved.addAll(userSaved);
      Set<String> set = Set.from(saved);
      saved = List<String>.from(set);
      return true;
    } on FirebaseAuthException catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
    }
    return false;
  }

  String get status => _status;

  set status(String status) {
    _status = status;
    notifyListeners();
  }

  User? get user => _user;

  set user(User? user) {
    _user = user;
    notifyListeners();
  }

  isAuthenticated() {
    return status == Status.Authenticated;
  }

  void logout() async {
    await syncSaved();
    status = Status.Unauthenticated;
    _auth.signOut();
    saved.clear();
    notifyListeners();
  }

  addUser(String email, String password, saved) async {
    var docRef = await _firestore.collection('users').add({
      'email': email,
      'password': password,
      'saved': saved,
      'uid': _user?.uid,
    });
    await docRef.update({'avatar': 'https://png.pngitem.com/pimgs/s/64-646593_thamali-k-i-s-user-default-image-jpg.png'});
    notifyListeners();
    return docRef;
  }
  getAvatar() async {
    var docRef = await _firestore.collection('users').where('uid', isEqualTo: _user?.uid).get();
    return docRef.docs[0].data()['avatar'];
  }
  changeAvatar(String url) async {
    var docRef = await _firestore.collection('users').where('uid', isEqualTo: _user?.uid).get();
    await docRef.docs[0].reference.update({'avatar': url});
    notifyListeners();
  }

  getSaved() async => await _firestore
      .collection('users')
      .where("uid", isEqualTo: _user?.uid)
      .get()
      .then((value) => value.docs[0].data()['saved']);

  syncSaved() async => await _firestore
      .collection('users')
      .where("uid", isEqualTo: _user?.uid)
      .get()
      .then((value) => value.docs[0].reference.update({'saved': saved}));

  void removeSaved(String word) {
    saved.remove(word);
    notifyListeners();
  }

  void addSaved(String word) {
    saved.add(word);
    notifyListeners();
  }
}

class Status {
  static const Uninitialized = "Uninitialized";
  static const Authenticated = "Authenticated";
  static const Authenticating = "Authenticating";
  static const Unauthenticated = "Unauthenticated";
}


