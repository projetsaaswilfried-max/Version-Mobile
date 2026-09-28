import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/supabase_support_datasource.dart';

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._remote);

  final SupabaseSupportDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<List<SupportTicket>>> fetchTickets() =>
      _guard(_remote.fetchTickets);

  @override
  Future<Result<List<SupportMessage>>> fetchMessages(String ticketId) =>
      _guard(() => _remote.fetchMessages(ticketId));

  @override
  Future<Result<SupportTicket>> openTicket({
    required String subject,
    required String message,
  }) => _guard(() => _remote.openTicket(subject: subject, message: message));

  @override
  Future<Result<void>> sendMessage({
    required String ticketId,
    required String message,
  }) => _guard(() => _remote.sendMessage(ticketId: ticketId, message: message));
}
