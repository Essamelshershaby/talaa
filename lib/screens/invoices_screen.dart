import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

class InvoicesScreen extends StatefulWidget {
  final String currentUserUid;
  final String currentUserRole;

  const InvoicesScreen({
    super.key,
    required this.currentUserUid,
    required this.currentUserRole,
  });

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // متحكمات حقول الإدخال لإضافة فاتورة جديدة
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedStatus = 'غير مدفوعة';
  
  final List<String> _statusOptions = [
    'مدفوعة',
    'غير مدفوعة',
    'قيد المراجعة',
  ];

  @override
  void dispose() {
    _clientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الفواتير',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // زر إضافة فاتورة (للمالك والمحاسب فقط)
        actions: [
          if (widget.currentUserRole == 'owner' || widget.currentUserRole == 'accountant')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddInvoiceDialog,
              tooltip: 'إضافة فاتورة',
            ),
        ],
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('invoices')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final invoices = snapshot.data!.docs;
          
          if (invoices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد فواتير',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final data = invoices[index].data() as Map<String, dynamic>;
              final docId = invoices[index].id;
              
              return _buildInvoiceCard(
                id: docId,
                client: data['client'] ?? 'بدون عميل',
                amount: data['amount'] ?? '0',
                status: data['status'] ?? 'غير مدفوعة',
                date: data['date'] as String?,
              );
            },
          );
        },
      ),
    );
  }

  // ==================== بناء بطاقة الفاتورة ====================
  
  Widget _buildInvoiceCard({
    required String id,
    required String client,
    required String amount,
    required String status,
    String? date,
  }) {
    // تحديد لون الحالة
    Color statusColor;
    switch (status) {
      case 'مدفوعة':
        statusColor = Colors.green;
        break;
      case 'قيد المراجعة':
        statusColor = Colors.orange;
        break;
      default:  // غير مدفوعة
        statusColor = Colors.red;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showInvoiceDetails(id, client, amount, status),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي
              Row(
                children: [
                  // أيقونة الفاتورة
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // اسم العميل
                  Expanded(
                    child: Text(
                      client,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // شريط الحالة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // المبلغ والتاريخ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // المبلغ
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  // التاريخ
                  if (date != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== عرض تفاصيل الفاتورة ====================
  
  void _showInvoiceDetails(String id, String client, String amount, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(client),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.attach_money, 'المبلغ', amount),
              const Divider(),
              _buildDetailRow(Icons.timeline, 'الحالة', status),
              const Divider(),
              _buildDetailRow(Icons.fingerprint, 'المعرف', id.substring(0, 15) + '...'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
            if (widget.currentUserRole == 'owner')
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(id, client);
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
          ],
        );
      },
    );
  }

  // ==================== بناء صف التفاصيل ====================
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== نافذة إضافة فاتورة جديدة ====================
  
  void _showAddInvoiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة فاتورة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // حقل اسم العميل
                TextField(
                  controller: _clientController,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                
                // حقل المبلغ
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                
                // قائمة منسدلة لاختيار الحالة
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'حالة الفاتورة',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timeline),
                  ),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearControllers();
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                _clearControllers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إضافة الفاتورة بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  // ==================== نافذة تأكيد الحذف ====================
  
  void _showDeleteConfirmDialog(String id, String client) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف فاتورة "$client"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الفاتورة'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ==================== تنظيف حقول الإدخال ====================
  
  void _clearControllers() {
    _clientController.clear();
    _amountController.clear();
    _selectedStatus = 'غير مدفوعة';
  }
}