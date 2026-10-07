import 'package:flutter/foundation.dart';
import '../models/billing.dart';
import '../models/payment_record.dart';
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
    PaymentRecord? paymentRecord,
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

      // Record to immutable payments ledger table if provided
      if (paymentRecord != null) {
        await insertPaymentRecord(paymentRecord);
      }

      return true;
    } catch (e) {
      debugPrint('[BillingService] Error recording payment: $e');
      return false;
    }
  }

  /// Inserts an immutable transaction row into public.payments ledger table
  Future<bool> insertPaymentRecord(PaymentRecord payment) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('payments').insert(payment.toMap());
      debugPrint('[BillingService] Payment ledger recorded: ${payment.id} for invoice ${payment.invoiceId}');
      return true;
    } catch (e) {
      debugPrint('[BillingService] Error inserting payment record: $e');
      return false;
    }
  }

  /// Fetches historical payment transaction records for a specific invoice
  Future<List<PaymentRecord>?> fetchPaymentsForInvoice(String invoiceId) async {
    final client = _supabase.client;
    if (client == null) {
      debugPrint('[BillingService] Supabase not active. Cannot fetch payments.');
      return null;
    }

    try {
      final data = await client
          .from('payments')
          .select()
          .eq('invoice_id', invoiceId)
          .order('payment_date', ascending: false);

      return (data as List<dynamic>)
          .map((m) => PaymentRecord.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[BillingService] Error fetching payments for invoice: $e');
      return null;
    }
  }

  Future<bool> insertInvoice(Invoice invoice) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      try {
        await client.from('invoices').upsert(invoice.toMap(includeExtendedFields: true));
      } catch (e) {
        await client.from('invoices').upsert(invoice.toMap(includeExtendedFields: false));
      }

      if (invoice.items.isNotEmpty) {
        final itemsData = invoice.items.map((it) {
          final m = it.toMap();
          m['invoice_id'] = invoice.id;
          return m;
        }).toList();
        await client.from('invoice_items').upsert(itemsData);
      }
      return true;
    } catch (e) {
      debugPrint('[BillingService] Error inserting invoice: $e');
      return false;
    }
  }
}
