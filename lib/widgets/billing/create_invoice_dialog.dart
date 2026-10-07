import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/billing.dart';
import '../../models/patient.dart';
import '../../state/clinic_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../common/app_button.dart';
import '../common/toast_notification.dart';

class _ProcedurePreset {
  final String name;
  final double defaultPrice;

  const _ProcedurePreset(this.name, this.defaultPrice);
}

const List<_ProcedurePreset> _commonProcedures = [
  _ProcedurePreset('Doctor Consultation Fee', 500),
  _ProcedurePreset('Full Mouth Scaling & Polishing', 1000),
  _ProcedurePreset('Composite Tooth Restoration / Filling', 1200),
  _ProcedurePreset('Root Canal Treatment (RCT)', 3500),
  _ProcedurePreset('Simple Tooth Extraction', 800),
  _ProcedurePreset('Surgical Extraction / Impaction', 3000),
  _ProcedurePreset('Ceramic Crown / Cap', 4500),
  _ProcedurePreset('Teeth Whitening / Bleaching', 6000),
  _ProcedurePreset('Dental X-Ray (IOPA)', 300),
  _ProcedurePreset('Fluoride / Desensitizing Treatment', 700),
  _ProcedurePreset('Custom / Other', -1),
];

/// Clinical Modal for Doctors to create a real patient bill/invoice
/// and route it to Receptionist for counter settlement.
class CreateInvoiceDialog extends StatefulWidget {
  final Patient? preselectedPatient;

  const CreateInvoiceDialog({super.key, this.preselectedPatient});

  static Future<bool?> show(BuildContext context, {Patient? patient}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateInvoiceDialog(preselectedPatient: patient),
    );
  }

  @override
  State<CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<CreateInvoiceDialog> {
  Patient? _selectedPatient;
  final List<InvoiceItem> _items = [];
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();

  // Custom Item Form Controllers
  final TextEditingController _itemDescController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final FocusNode _itemDescFocusNode = FocusNode();
  int _itemQuantity = 1;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.preselectedPatient;

    // Default with consultation fee if opening fresh
    _items.add(
      const InvoiceItem(
        description: 'Doctor Consultation Fee',
        quantity: 1,
        unitPrice: 500.0,
        amount: 500.0,
      ),
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    _itemDescController.dispose();
    _itemPriceController.dispose();
    _itemDescFocusNode.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.amount);

  double get _discount {
    final d = double.tryParse(_discountController.text) ?? 0.0;
    return d.clamp(0.0, _subtotal);
  }

  double get _total => (_subtotal - _discount).clamp(0.0, double.infinity);

  void _addItem(String description, double price, int qty) {
    if (description.trim().isEmpty || price <= 0 || qty <= 0) return;
    setState(() {
      _items.add(
        InvoiceItem(
          description: description.trim(),
          quantity: qty,
          unitPrice: price,
          amount: price * qty,
        ),
      );
      _itemDescController.clear();
      _itemPriceController.clear();
      _itemQuantity = 1;
      _errorMessage = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    final patient = _selectedPatient;
    if (patient == null) {
      setState(() => _errorMessage = 'Please select a patient for this bill.');
      return;
    }

    if (_items.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one procedure or treatment item.');
      return;
    }

    if (_total <= 0 && _subtotal <= 0) {
      setState(() => _errorMessage = 'Invoice total amount must be greater than zero.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final staffProfile = AuthService.instance.currentProfile;
    final doctorName = staffProfile?.fullName.isNotEmpty == true
        ? staffProfile!.fullName
        : 'Dr. Rahul Sharma';
    final doctorId = staffProfile?.id ?? 'DOC-01';

    final now = DateTime.now();
    final String invId = 'INV-${now.millisecondsSinceEpoch}';
    final String invNumber = 'INV-2026-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final invoice = Invoice(
      id: invId,
      invoiceNumber: invNumber,
      patientId: patient.id,
      patientName: patient.name,
      patientPhone: patient.phone,
      doctorId: doctorId,
      doctorName: doctorName,
      date: now,
      items: List.from(_items),
      subtotal: _subtotal,
      discount: _discount,
      tax: 0.0,
      totalAmount: _total,
      paidAmount: 0.0,
      balanceAmount: _total,
      status: PaymentStatus.pending,
      paymentMethod: 'Pending Counter Payment',
      notes: _notesController.text.trim(),
      receiptNumber: '',
      receivedBy: '',
      paymentStatusText: 'Pending',
    );

    final success = await context.clinic.addInvoice(invoice);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(true);
      AppFeedback.showSuccess(
        context,
        'Bill created for ${patient.name} (${invoice.invoiceNumber}) & routed to Receptionist.',
      );
    } else {
      setState(() {
        _errorMessage = 'Failed to save billing information to Supabase database. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final patients = clinic.patients;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long, color: AppColors.primaryDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Create Patient Bill', style: AppTextStyles.h3),
                        Text(
                          'Generate clinical invoice and route to Receptionist for counter payment',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF87171)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Selector / Info
                      if (widget.preselectedPatient != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryLight,
                                child: Icon(Icons.person, color: AppColors.primaryDark, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.preselectedPatient!.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    Text(
                                      'ID: ${widget.preselectedPatient!.id} • Phone: ${widget.preselectedPatient!.phone}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<Patient>(
                          value: _selectedPatient,
                          decoration: const InputDecoration(
                            labelText: 'Select Patient *',
                            prefixIcon: Icon(Icons.person_search_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: patients.map((p) {
                            return DropdownMenuItem<Patient>(
                              value: p,
                              child: Text('${p.name} (${p.phone})'),
                            );
                          }).toList(),
                          onChanged: (p) => setState(() => _selectedPatient = p),
                        ),

                      const SizedBox(height: 16),

                      // Treatment Procedures Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Procedure Line Items *', style: AppTextStyles.h4),
                          PopupMenuButton<_ProcedurePreset>(
                            tooltip: 'Add standard clinical procedure',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.add, size: 14, color: AppColors.primaryDark),
                                  SizedBox(width: 4),
                                  Text(
                                    'Quick Add Procedure',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onSelected: (preset) {
                              if (preset.defaultPrice < 0) {
                                _itemDescFocusNode.requestFocus();
                                setState(() {
                                  _errorMessage = 'Enter description and price for the custom item below.';
                                });
                              } else {
                                _addItem(preset.name, preset.defaultPrice, 1);
                              }
                            },
                            itemBuilder: (ctx) => _commonProcedures.map((preset) {
                              final isCustom = preset.defaultPrice < 0;
                              return PopupMenuItem<_ProcedurePreset>(
                                value: preset,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(preset.name, style: TextStyle(fontSize: 12, fontWeight: isCustom ? FontWeight.w700 : FontWeight.normal)),
                                    const SizedBox(width: 12),
                                    Text(
                                      isCustom ? 'Custom' : '₹${preset.defaultPrice.toInt()}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isCustom ? AppColors.primaryDark : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Procedures List Table
                      if (_items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Center(
                            child: Text(
                              'No line items added yet. Click "+ Quick Add Procedure" above or add custom.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (c, i) => const Divider(height: 1, color: AppColors.borderLight),
                            itemBuilder: (context, idx) {
                              final item = _items[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                          Text(
                                            'Qty: ${item.quantity}  ×  ₹${item.unitPrice.toStringAsFixed(0)}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      currency.format(item.amount),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _removeItem(idx),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Custom Item Adder Row
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: TextField(
                                controller: _itemDescController,
                                focusNode: _itemDescFocusNode,
                                decoration: const InputDecoration(
                                  hintText: 'Custom item / procedure description *',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _itemPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '₹ Price *',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              tooltip: 'Add custom item',
                              onPressed: () {
                                final desc = _itemDescController.text.trim();
                                final price = double.tryParse(_itemPriceController.text.trim()) ?? 0.0;
                                if (desc.isEmpty) {
                                  setState(() => _errorMessage = 'Please enter a description for the custom procedure.');
                                  return;
                                }
                                if (price <= 0) {
                                  setState(() => _errorMessage = 'Custom procedure amount must be greater than zero.');
                                  return;
                                }
                                _addItem(desc, price, _itemQuantity);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Discount & Notes
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Discount (₹)',
                                prefixText: '₹ ',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Doctor Billing Notes (Optional)',
                                hintText: 'e.g. Scaling warranty, tooth #14 RCT',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Totals Summary Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:', style: TextStyle(fontSize: 13, color: Color(0xFF374151))),
                                Text(currency.format(_subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (_discount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount:', style: TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
                                  Text('- ${currency.format(_discount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                                ],
                              ),
                            ],
                            const Divider(height: 14, color: Color(0xFFBBF7D0)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Payable at Reception:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF14532D))),
                                Text(
                                  currency.format(_total),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.ghost(
                    text: 'Cancel',
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: _isSaving ? 'Saving to Database...' : 'Save & Route to Reception',
                    icon: _isSaving ? null : Icons.check_circle_outline,
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
