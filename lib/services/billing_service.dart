import 'package:flutter/foundation.dart';
import '../models/billing.dart';
import 'supabase_service.dart';

class BillingService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<Invoice>?> fetchInvoices() async {
    final client = _supabase.client;
    if (client == null) return null;

    try {
      final invoiceData = await client
          .from('invoices')
          .select()
          .order('date', ascending: false);

      final List<Invoice> result = [];
      for (final invMap in (invoiceData as List<dynamic>)) {
        final invId = invMap['id'].toString();
        // Fetch items for this invoice
        final itemsData = await client
            .from('invoice_items')
            .select()
            .eq('invoice_id', invId);

        final items = (itemsData as List<dynamic>)
            .map((itemMap) => InvoiceItem.fromMap(itemMap as Map<String, dynamic>))
            .toList();

        result.add(Invoice.fromMap(invMap as Map<String, dynamic>, items: items));
      }

      return result;
    } catch (e) {
      debugPrint('[BillingService] Error fetching invoices: $e');
      return null;
    }
  }

  Future<bool> recordPayment({
    required String invoiceId,
    required double newPaidAmount,
    required double newBalanceAmount,
    required PaymentStatus newStatus,
    required String paymentMethod,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('invoices').update({
        'paid_amount': newPaidAmount,
        'balance_amount': newBalanceAmount,
        'status': newStatus.name,
        'payment_method': paymentMethod,
      }).eq('id', invoiceId);
      return true;
    } catch (e) {
      debugPrint('[BillingService] Error recording payment: $e');
      return false;
    }
  }
}
