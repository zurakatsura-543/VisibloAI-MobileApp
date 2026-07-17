import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/models/test_account.dart';

class LocalAuthService extends GetxService {
  static const _accountsKey = 'test_accounts';
  static const _sessionEmailKey = 'test_session_email';

  final currentUser = Rxn<TestAccount>();

  late final SharedPreferences _preferences;
  final List<TestAccount> _accounts = <TestAccount>[];

  Future<LocalAuthService> init() async {
    _preferences = await SharedPreferences.getInstance();
    await _loadAccounts();

    final sessionEmail = _preferences.getString(_sessionEmailKey);
    if (sessionEmail != null) {
      currentUser.value = _findAccountByEmail(sessionEmail);
    }

    return this;
  }

  bool get isLoggedIn => currentUser.value != null;

  bool accountExists(String email) {
    return _findAccountByEmail(email.trim()) != null;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final account = _findAccountByEmail(normalizedEmail);

    if (account == null) {
      return 'No test account found for this email. Please sign up first.';
    }

    if (account.password != password) {
      return 'The password is incorrect for this test account.';
    }

    currentUser.value = account;
    await _preferences.setString(_sessionEmailKey, account.email);
    return null;
  }

  Future<String?> registerAccount(TestAccount account) async {
    final normalizedEmail = account.email.trim().toLowerCase();
    if (accountExists(normalizedEmail)) {
      return 'An account with this email already exists. Please log in instead.';
    }

    final normalizedAccount = account.copyWith(email: normalizedEmail);
    _accounts.add(normalizedAccount);
    await _persistAccounts();

    currentUser.value = normalizedAccount;
    await _preferences.setString(_sessionEmailKey, normalizedAccount.email);
    return null;
  }

  Future<void> updateCurrentUser(TestAccount account) async {
    final normalizedAccount = account.copyWith(
      email: account.email.trim().toLowerCase(),
    );
    final existingIndex = _accounts.indexWhere(
      (savedAccount) =>
          savedAccount.email.toLowerCase() == normalizedAccount.email,
    );

    if (existingIndex >= 0) {
      _accounts[existingIndex] = normalizedAccount;
    } else {
      _accounts.add(normalizedAccount);
    }

    currentUser.value = normalizedAccount;
    await _persistAccounts();
    await _preferences.setString(_sessionEmailKey, normalizedAccount.email);
  }

  Future<void> logout() async {
    currentUser.value = null;
    await _preferences.remove(_sessionEmailKey);
  }

  Future<void> deleteCurrentAccount() async {
    final user = currentUser.value;
    if (user == null) {
      return;
    }

    final normalizedEmail = user.email.trim().toLowerCase();
    _accounts.removeWhere(
      (savedAccount) =>
          savedAccount.email.trim().toLowerCase() == normalizedEmail,
    );

    currentUser.value = null;
    await _persistAccounts();
    await _preferences.remove(_sessionEmailKey);
  }

  Future<void> _loadAccounts() async {
    final encodedAccounts =
        _preferences.getStringList(_accountsKey) ?? <String>[];
    _accounts
      ..clear()
      ..addAll(
        encodedAccounts.map(
          (entry) =>
              TestAccount.fromMap(jsonDecode(entry) as Map<String, dynamic>),
        ),
      );
  }

  Future<void> _persistAccounts() async {
    await _preferences.setStringList(
      _accountsKey,
      _accounts.map((account) => jsonEncode(account.toMap())).toList(),
    );
  }

  TestAccount? _findAccountByEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();

    for (final account in _accounts) {
      if (account.email.toLowerCase() == normalizedEmail) {
        return account;
      }
    }

    return null;
  }
}
