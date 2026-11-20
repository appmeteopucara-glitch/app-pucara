import 'package:pronosticosapp/features/auth/domain/entities/delete_account_result.dart';
import 'package:pronosticosapp/features/auth/domain/repositories/auth_repository.dart';

class DeleteAccount {
  final AuthRepository repository;
  DeleteAccount(this.repository);
  Future<DeleteAccountResult> call(String password) {
    return repository.deleteAccount(password: password);
  }
}
