// ============================================================
// ملف: screens/employees_screen.dart
// الوظيفة: صفحة إدارة الموظفين (للمالك فقط) - تعرض جميع الموظفين المسجلين
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

class EmployeesScreen extends StatefulWidget {
  final String currentUserUid;
  final String currentUserRole;

  const EmployeesScreen({
    super.key,
    required this.currentUserUid,
    required this.currentUserRole,
  });

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // متغيرات لإضافة موظف جديد
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'member';

  // متغيرات للبحث
  String _searchQuery = '';

  // متغير للتحميل
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة الموظفين',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // زر إضافة موظف جديد (للمالك فقط)
          if (widget.currentUserRole == 'owner')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddEmployeeDialog,
              tooltip: 'إضافة موظف',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'البحث عن موظف...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 جلب جميع المستخدمين من قاعدة البيانات 🔥
        stream: _firestore
            .collection('users')
            .orderBy('name') // ترتيب حسب الاسم
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('حدث خطأ: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // جلب جميع المستخدمين
          var employees = snapshot.data!.docs;

          // 🔥 تصفية حسب البحث 🔥
          if (_searchQuery.isNotEmpty) {
            employees = employees.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toLowerCase();
              final email = (data['email'] ?? '').toLowerCase();
              return name.contains(_searchQuery) ||
                  email.contains(_searchQuery);
            }).toList();
          }

          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'لا يوجد موظفين في الشركة'
                        : 'لا توجد نتائج للبحث',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child: const Text('مسح البحث'),
                    ),
                ],
              ),
            );
          }

          // عرض قائمة الموظفين
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final data = employees[index].data() as Map<String, dynamic>;
              final docId = employees[index].id;

              // 🔥 عدم عرض المستخدم الحالي في القائمة (اختياري) 🔥
              if (docId == widget.currentUserUid) {
                // تخطي المستخدم الحالي (اختياري)
                // return const SizedBox.shrink();
              }

              return _buildEmployeeCard(
                uid: docId,
                name: data['name'] ?? 'بدون اسم',
                email: data['email'] ?? '',
                role: data['role'] ?? 'member',
                phone: data['phone'] ?? '',
                department: data['department'] ?? '',
                position: data['position'] ?? '',
                hireDate: data['hireDate'] ?? '',
                isActive: data['isActive'] ?? true,
                salary: data['salary'] != null ? data['salary'].toString() : '',
              );
            },
          );
        },
      ),
    );
  }

  // ==================== بناء بطاقة الموظف ====================

  Widget _buildEmployeeCard({
    required String uid,
    required String name,
    required String email,
    required String role,
    required String phone,
    required String department,
    required String position,
    required String hireDate,
    required bool isActive,
    required String salary,
  }) {
    // تحديد لون ونص الصلاحية
    Color roleColor;
    String roleText;

    switch (role) {
      case 'owner':
        roleColor = Colors.blue;
        roleText = 'مالك';
        break;
      case 'accountant':
        roleColor = Colors.green;
        roleText = 'محاسب';
        break;
      default:
        roleColor = Colors.orange;
        roleText = 'عضو';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showEmployeeDetails(
          uid,
          name,
          email,
          role,
          phone,
          department,
          position,
          hireDate,
          salary,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // الصورة الرمزية
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0] : 'م',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // معلومات الموظف
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (position.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        position,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // شريط الصلاحية
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleText,
                  style: TextStyle(
                    fontSize: 12,
                    color: roleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // حالة الحساب (نشط/غير نشط)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green : Colors.red,
                ),
              ),

              const SizedBox(width: 8),

              // سهم التفاصيل
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== عرض تفاصيل الموظف ====================

  void _showEmployeeDetails(
    String uid,
    String name,
    String email,
    String role,
    String phone,
    String department,
    String position,
    String hireDate,
    String salary,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(name)),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.email, 'البريد الإلكتروني', email),
                const Divider(),
                _buildDetailRow(Icons.phone, 'رقم الهاتف',
                    phone.isEmpty ? 'غير مضاف' : phone),
                const Divider(),
                _buildDetailRow(
                    Icons.admin_panel_settings, 'الصلاحية', _getRoleText(role)),
                const Divider(),
                _buildDetailRow(
                    Icons.monetization_on,
                    'الراتب',
                    salary != null && salary.toString().isNotEmpty
                        ? '${salary} ₪'
                        : 'غير مضاف'),
                const Divider(),
                if (department.isNotEmpty)
                  _buildDetailRow(Icons.business, 'القسم', department),
                if (position.isNotEmpty) ...[
                  const Divider(),
                  _buildDetailRow(Icons.work, 'الوظيفة', position),
                ],
                if (hireDate.isNotEmpty) ...[
                  const Divider(),
                  _buildDetailRow(
                      Icons.calendar_today, 'تاريخ التعيين', hireDate),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
            if (widget.currentUserRole == 'owner' &&
                uid != widget.currentUserUid)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(uid, name);
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
            width: 100,
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

  // ==================== نافذة إضافة موظف جديد ====================

  void _showAddEmployeeDialog() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedRole = 'member';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة موظف جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'الصلاحية',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'member', child: Text('عضو / مهندس')),
                    DropdownMenuItem(value: 'accountant', child: Text('محاسب')),
                    DropdownMenuItem(
                        value: 'owner', child: Text('مالك / مدير')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: _addEmployee,
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  // ==================== إضافة موظف جديد ====================

  Future<void> _addEmployee() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('الرجاء إدخال الاسم');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showMessage('الرجاء إدخال البريد الإلكتروني');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showMessage('الرجاء إدخال كلمة المرور');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🔥 هنا هتضيف منطق إضافة المستخدم إلى Firebase Auth و Firestore 🔥
      // حالياً مجرد محاكاة

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
        _showMessage('تم إضافة الموظف بنجاح');
      }
    } catch (e) {
      _showMessage('حدث خطأ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==================== نافذة تأكيد الحذف ====================

  void _showDeleteConfirmDialog(String uid, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف الموظف "$name"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                _showMessage('تم حذف الموظف');
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ==================== دوال مساعدة ====================

  String _getRoleText(String role) {
    switch (role) {
      case 'owner':
        return 'مالك / مدير عام';
      case 'accountant':
        return 'محاسب';
      default:
        return 'عضو / مهندس';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
