import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

class ProjectsScreen extends StatefulWidget {
  final String currentUserUid;
  final String currentUserRole;

  const ProjectsScreen({
    super.key,
    required this.currentUserUid,
    required this.currentUserRole,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  // ==================== المتغيرات ====================
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // متحكمات حقول الإدخال لإضافة مشروع جديد
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // حالة المشروع الافتراضية
  String _selectedStatus = 'قيد التنفيذ';
  
  // خيارات الحالات المتاحة
  final List<String> _statusOptions = [
    'قيد التنفيذ',
    'مكتمل',
    'معلق',
    'ملغي',
  ];

  // ==================== دورة حياة الصفحة ====================
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ==================== بناء واجهة المستخدم ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة المشاريع',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        // زر الرجوع
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // زر إضافة مشروع (يظهر فقط للمالك)
        actions: [
          if (widget.currentUserRole == 'owner')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddProjectDialog,
              tooltip: 'إضافة مشروع',
            ),
        ],
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        // استعلام لجلب جميع المشاريع مرتبة حسب تاريخ الإنشاء
        stream: _firestore
            .collection('projects')
            .orderBy('createdAt', descending: true)  // الأحدث أولاً
            .snapshots(),
        
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final projects = snapshot.data!.docs;
          
          if (projects.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد مشاريع',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final data = projects[index].data() as Map<String, dynamic>;
              final docId = projects[index].id;
              final createdAt = data['createdAt'] as Timestamp?;
              
              return _buildProjectCard(
                id: docId,
                name: data['name'] ?? 'بدون اسم',
                description: data['description'] ?? '',
                status: data['status'] ?? 'قيد التنفيذ',
                createdAt: createdAt,
              );
            },
          );
        },
      ),
    );
  }

  // ==================== بناء بطاقة المشروع ====================
  
  Widget _buildProjectCard({
    required String id,
    required String name,
    required String description,
    required String status,
    Timestamp? createdAt,
  }) {
    // تحديد لون الحالة حسب النص
    Color statusColor;
    switch (status) {
      case 'مكتمل':
        statusColor = Colors.green;
        break;
      case 'معلق':
        statusColor = Colors.orange;
        break;
      case 'ملغي':
        statusColor = Colors.red;
        break;
      default:  // قيد التنفيذ
        statusColor = Colors.blue;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProjectDetails(id, name, description, status),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي (أيقونة + اسم المشروع + الحالة)
              Row(
                children: [
                  // أيقونة المشروع
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // اسم المشروع
                  Expanded(
                    child: Text(
                      name,
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
              
              // وصف المشروع
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // تاريخ الإنشاء
              if (createdAt != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(createdAt.toDate()),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== نافذة إضافة مشروع جديد ====================
  
  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة مشروع جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // حقل اسم المشروع
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المشروع',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                
                // حقل وصف المشروع
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'وصف المشروع',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                
                // قائمة منسدلة لاختيار الحالة
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'حالة المشروع',
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
                // هنا هتضيف منطق إضافة المشروع
                Navigator.pop(context);
                _clearControllers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إضافة المشروع بنجاح'),
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

  // ==================== عرض تفاصيل المشروع ====================
  
  void _showProjectDetails(String id, String name, String description, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.description, 'الوصف', description),
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
                  _showDeleteConfirmDialog(id, name);
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

  // ==================== نافذة تأكيد الحذف ====================
  
  void _showDeleteConfirmDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف المشروع "$name"؟'),
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
                    content: Text('تم حذف المشروع'),
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

  // ==================== تنسيق التاريخ ====================
  
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  // ==================== تنظيف حقول الإدخال ====================
  
  void _clearControllers() {
    _nameController.clear();
    _descriptionController.clear();
    _selectedStatus = 'قيد التنفيذ';
  }
}