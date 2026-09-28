import '../../../../core/error/result.dart';
import '../entities/support_ticket.dart';

abstract class SupportRepository {
  Future<Result<List<SupportTicket>>> fetchTickets();
  Future<Result<List<SupportMessage>>> fetchMessages(String ticketId);
  Future<Result<SupportTicket>> openTicket({
    required String subject,
    required String message,
  });
  Future<Result<void>> sendMessage({
    required String ticketId,
    required String message,
  });
}
