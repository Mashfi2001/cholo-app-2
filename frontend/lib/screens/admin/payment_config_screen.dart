import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import '../../backend_config.dart';

class PaymentConfigScreen extends StatefulWidget {
  const PaymentConfigScreen({super.key});

  @override
  State<PaymentConfigScreen> createState() => _PaymentConfigScreenState();
}

class _PaymentConfigScreenState extends State<PaymentConfigScreen> {
  List<dynamic> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/admin/payment-methods'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _paymentMethods = data['methods'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading payment methods: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMethod(int methodId, bool isEnabled) async {
    try {
      final response = await http.patch(
        Uri.parse('$backendUrl/api/admin/payment-methods/$methodId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isEnabled': isEnabled}),
      );

      if (response.statusCode == 200) {
        _loadPaymentMethods();
      }
    } catch (e) {
      print('Error toggling method: $e');
    }
  }

  void _showAddMethodSheet() {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.payment;

    final List<Map<String, dynamic>> iconOptions = [
      {'icon': Icons.money, 'name': 'Cash'},
      {'icon': Icons.account_balance_wallet, 'name': 'Wallet'},
      {'icon': Icons.credit_card, 'name': 'Card'},
      {'icon': Icons.phone_android, 'name': 'Mobile'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceBlack,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Add Payment Method',
                  style: AppTextStyles.headingL,
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBlack,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: TextField(
                    controller: nameController,
                    style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                    decoration: InputDecoration(
                      hintText: 'Method name (e.g., bKash)',
                      hintStyle: AppTextStyles.bodyM,
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Icon',
                  style: AppTextStyles.bodyM,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: iconOptions.map((option) {
                    final isSelected = selectedIcon == option['icon'];
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedIcon = option['icon'];
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.pureWhite 
                              : AppColors.cardBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? AppColors.pureWhite 
                                : AppColors.borderGray,
                          ),
                        ),
                        child: Icon(
                          option['icon'],
                          color: isSelected 
                              ? AppColors.primaryBlack 
                              : AppColors.silverLight,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Add Method',
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      _addMethod(nameController.text.trim(), selectedIcon);
                    }
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Cancel',
                  variant: CustomButtonVariant.secondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addMethod(String name, IconData icon) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/admin/payment-methods'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'icon': icon.codePoint,
        }),
      );

      if (response.statusCode == 201) {
        _loadPaymentMethods();
      }
    } catch (e) {
      print('Error adding method: $e');
    }
  }

  Future<void> _deleteMethod(int methodId) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceBlack,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.delete,
              color: AppColors.dangerRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Payment Method?',
              style: AppTextStyles.headingL,
            ),
            const SizedBox(height: 8),
            Text(
              'This will remove the payment method from the app.',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Delete',
              variant: CustomButtonVariant.danger,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Cancel',
              variant: CustomButtonVariant.secondary,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/api/admin/payment-methods/$methodId'),
      );

      if (response.statusCode == 200) {
        _loadPaymentMethods();
      }
    } catch (e) {
      print('Error deleting method: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment Methods',
                      style: AppTextStyles.headingM,
                    ),
                  ),
                ],
              ),
            ),

            // Payment methods list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pureWhite),
                    )
                  : _paymentMethods.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, color: AppColors.silverMid, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'No payment methods',
                                style: AppTextStyles.headingL.copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _paymentMethods.length,
                          itemBuilder: (context, index) {
                            final method = _paymentMethods[index];
                            return _buildMethodCard(method);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMethodSheet,
        backgroundColor: AppColors.pureWhite,
        foregroundColor: AppColors.primaryBlack,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForMethod(String name) {
    switch (name.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'bkash':
      case 'nagad':
        return Icons.account_balance_wallet;
      case 'card':
        return Icons.credit_card;
      case 'mobile':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  Widget _buildMethodCard(dynamic method) {
    final name = method['name'] ?? 'Unknown';
    final isEnabled = method['isEnabled'] ?? false;
    final icon = _getIconForMethod(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? AppColors.borderGray : AppColors.silverMid.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled 
                  ? AppColors.pureWhite.withOpacity(0.1) 
                  : AppColors.surfaceBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isEnabled ? AppColors.pureWhite : AppColors.silverMid,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyL.copyWith(
                    color: isEnabled ? AppColors.pureWhite : AppColors.silverMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled ? 'Enabled' : 'Disabled',
                  style: AppTextStyles.caption.copyWith(
                    color: isEnabled ? AppColors.successGreen : AppColors.silverMid,
                  ),
                ),
              ],
            ),
          ),
          // Toggle switch
          GestureDetector(
            onTap: () => _toggleMethod(method['id'], !isEnabled),
            child: Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: isEnabled ? AppColors.pureWhite : AppColors.surfaceBlack,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isEnabled ? AppColors.pureWhite : AppColors.borderGray,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isEnabled 
                    ? Alignment.centerRight 
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isEnabled ? AppColors.primaryBlack : AppColors.silverMid,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          IconButton(
            onPressed: () => _deleteMethod(method['id']),
            icon: const Icon(Icons.more_vert, color: AppColors.silverMid),
          ),
        ],
      ),
    );
  }
}
