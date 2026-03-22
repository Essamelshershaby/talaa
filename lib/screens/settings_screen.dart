// ============================================================
// ملف: screens/settings_screen.dart
// الوظيفة: صفحة الإعدادات الشخصية للمستخدم
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  final String currentUserUid;
  final String currentUserRole;
  final Function? onProfileUpdated;

  const SettingsScreen({
    super.key,
    required this.currentUserUid,
    required this.currentUserRole,
    this.onProfileUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ==================== المتغيرات ====================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // متغيرات الإعدادات
  bool _notificationsEnabled = true;

  // متغيرات بيانات المستخدم
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String? _userAvatarUrl;
  String _userHireDate = ''; // تاريخ التعيين
  String _userDepartment = ''; // القسم
  String _userPosition = ''; // الوظيفة
  String _userAddress = ''; // العنوان
  String _userEmergencyContact = ''; // رقم الطوارئ
  String _serviceDuration = ''; // لحساب مدة الخدمة
  File? _selectedImage;
  bool _isLoading = false;

  // متحكمات حقول الإدخال
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _hireDateController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyController = TextEditingController();

  // اختيار الصورة
  final ImagePicker _picker = ImagePicker();

  // ==================== دورة حياة الصفحة ====================

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // التأكد من أن الـ context جاهز
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _hireDateController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _addressController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

// ==================== تنظيف تنسيق التاريخ ====================

String _cleanDateFormat(String date) {
  if (date.isEmpty) return '';
  
  try {
    // محاولة تحويل التاريخ
    DateTime parsedDate = DateTime.parse(date);
    String year = parsedDate.year.toString();
    String month = parsedDate.month.toString().padLeft(2, '0');
    String day = parsedDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  } catch (e) {
    // إذا فشل التحويل، أرجع التاريخ الأصلي
    print('خطأ في تنظيف التاريخ: $date');
    return date;
  }
}




  // ==================== جلب بيانات المستخدم ====================

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.currentUserUid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? '';
          _userEmail = data['email'] ?? '';
          _userPhone = data['phone'] ?? '';
          _userAvatarUrl = data['avatarUrl'];
          _userHireDate = _cleanDateFormat(data['hireDate'] ?? '');
          _serviceDuration = _calculateServiceDuration(_userHireDate);
          _userDepartment = data['department'] ?? '';
          _userPosition = data['position'] ?? '';
          _userAddress = data['address'] ?? '';
          _userEmergencyContact = data['emergencyContact'] ?? '';

          _nameController.text = _userName;
          _phoneController.text = _userPhone;
          _hireDateController.text = _userHireDate;
          _departmentController.text = _userDepartment;
          _positionController.text = _userPosition;
          _addressController.text = _userAddress;
          _emergencyController.text = _userEmergencyContact;
        });
      }
    } catch (e) {
      _showMessage('حدث خطأ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _calculateServiceDuration(String hireDate) {
  // إذا كان التاريخ فارغ
  if (hireDate.isEmpty) {
    return 'لم يتم تحديد تاريخ التعيين';
  }
  
  try {
    DateTime startDate;
    
    // 🔥 محاولة قراءة التاريخ بأكثر من صيغة 🔥
    if (hireDate.contains('-')) {
      // صيغة: 2024-01-15
      List<String> parts = hireDate.split('-');
      if (parts.length >= 3) {
        startDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        return 'تنسيق تاريخ غير صحيح';
      }
    } else if (hireDate.contains('/')) {
      // صيغة: 2024/01/15
      List<String> parts = hireDate.split('/');
      if (parts.length >= 3) {
        startDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        return 'تنسيق تاريخ غير صحيح';
      }
    } else {
      // محاولة قراءة التاريخ مباشرة
      try {
        startDate = DateTime.parse(hireDate);
      } catch (e) {
        return 'تنسيق تاريخ غير صحيح';
      }
    }
    
    DateTime now = DateTime.now();
    
    // التأكد من أن التاريخ صحيح
    if (startDate.isAfter(now)) {
      return 'تاريخ مستقبلي غير صحيح';
    }
    
    int years = now.year - startDate.year;
    int months = now.month - startDate.month;
    int days = now.day - startDate.day;
    
    if (months < 0) {
      years--;
      months += 12;
    }
    
    if (days < 0) {
      months--;
      DateTime previousMonth = DateTime(now.year, now.month, 0);
      days += previousMonth.day;
    }
    
    List<String> partsList = [];
    
    // عرض السنوات
    if (years > 0) {
      if (years == 1) {
        partsList.add('سنة');
      } else if (years == 2) {
        partsList.add('سنتان');
      } else {
        partsList.add('$years سنوات');
      }
    }
    
    // عرض الأشهر
    if (months > 0) {
      if (months == 1) {
        partsList.add('شهر');
      } else if (months == 2) {
        partsList.add('شهران');
      } else {
        partsList.add('$months أشهر');
      }
    }
    
    // عرض الأيام (فقط إذا كانت السنوات والأشهر صفر)
    if (days > 0 && years == 0 && months == 0) {
      if (days == 1) {
        partsList.add('يوم');
      } else if (days == 2) {
        partsList.add('يومان');
      } else {
        partsList.add('$days أيام');
      }
    }
    
    if (partsList.isEmpty) {
      return 'أقل من شهر';
    }
    
    return partsList.join(' و ');
    
  } catch (e) {
    // 🔥 طباعة الخطأ للمساعدة في التصحيح 🔥
    print('خطأ في حساب مدة الخدمة: $e');
    print('التاريخ المدخل: $hireDate');
    return 'تنسيق تاريخ غير صحيح';
  }
}

  // ==================== رفع الصورة إلى Firebase Storage ====================

  Future<String?> _uploadImage(File image) async {
    try {
      String fileName =
          '${widget.currentUserUid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('profile_images/$fileName');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _showMessage('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  // ==================== حفظ بيانات المستخدم ====================

  Future<void> _saveUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'hireDate': _hireDateController.text.trim(),
        'department': _departmentController.text.trim(),
        'position': _positionController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContact': _emergencyController.text.trim(),
      };

      if (_selectedImage != null) {
        String? imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl != null) {
          updateData['avatarUrl'] = imageUrl;
        }
      }

      await _firestore
          .collection('users')
          .doc(widget.currentUserUid)
          .update(updateData);

      setState(() {
        _userName = _nameController.text;
        _userPhone = _phoneController.text;
        _userHireDate = _hireDateController.text;
        _serviceDuration = _calculateServiceDuration(_userHireDate);
        _userDepartment = _departmentController.text;
        _userPosition = _positionController.text;
        _userAddress = _addressController.text;
        _userEmergencyContact = _emergencyController.text;
        if (_selectedImage != null) {
          _userAvatarUrl = updateData['avatarUrl'];
        }
      });

      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }

      _showMessage('تم حفظ التغييرات بنجاح');
    } catch (e) {
      _showMessage('حدث خطأ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================== نافذة تعديل القيمة ====================

  void _showEditDialog({
    required String title,
    required String currentValue,
    required Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'أدخل $title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: keyboardType,
            maxLines: maxLines,
            textDirection: TextDirection.rtl,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (controller.text.trim().isNotEmpty) {
                  onSave(controller.text.trim());
                } else {
                  _showMessage('لا يمكن ترك الحقل فارغاً');
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  // ==================== اختيار تاريخ التعيين ====================

  Future<void> _selectDate() async {
  if (widget.currentUserRole != 'owner') {
    _showMessage('غير مسموح لك بتعديل تاريخ التعيين');
    return;
  }
  
  if (!mounted) return;
  
  try {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _userHireDate.isNotEmpty
          ? DateTime.tryParse(_userHireDate) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'SA'),
    );
    
    if (pickedDate != null && mounted) {
      // 🔥 تأكد من التنسيق: سنة-شهر-يوم 🔥
      String year = pickedDate.year.toString();
      String month = pickedDate.month.toString().padLeft(2, '0');
      String day = pickedDate.day.toString().padLeft(2, '0');
      String formattedDate = '$year-$month-$day';
      
      setState(() {
        _hireDateController.text = formattedDate;
        _userHireDate = formattedDate;
        _serviceDuration = _calculateServiceDuration(formattedDate);
      });
      await _saveUserData();
    }
  } catch (e) {
    if (mounted) {
      _showMessage('حدث خطأ في اختيار التاريخ: $e');
    }
  }
}

  // ==================== اختيار صورة من المعرض ====================

  Future<void> _pickImage() async {
    PermissionStatus status = await Permission.photos.request();

    if (status.isGranted) {
      try {
        final pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 500,
          maxHeight: 500,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            _selectedImage = File(pickedFile.path);
          });
          _showMessage('تم اختيار الصورة بنجاح، اضغط حفظ لتأكيد التغيير');
        }
      } catch (e) {
        _showMessage('حدث خطأ: $e');
      }
    } else if (status.isDenied) {
      _showMessage('الرجاء السماح بالوصول إلى المعرض من إعدادات الجهاز');
    } else if (status.isPermanentlyDenied) {
      _showMessage('الرجاء تفعيل إذن المعرض من إعدادات الجهاز');
      openAppSettings();
    }
  }

  // ==================== التقاط صورة بالكاميرا ====================

  Future<void> _takePhoto() async {
    PermissionStatus status = await Permission.camera.request();

    if (status.isGranted) {
      try {
        final pickedFile = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 500,
          maxHeight: 500,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            _selectedImage = File(pickedFile.path);
          });
          _showMessage('تم التقاط الصورة بنجاح، اضغط حفظ لتأكيد التغيير');
        }
      } catch (e) {
        _showMessage('حدث خطأ في التقاط الصورة: $e');
      }
    } else if (status.isDenied) {
      _showMessage('الرجاء السماح بالوصول إلى الكاميرا من إعدادات الجهاز');
    } else if (status.isPermanentlyDenied) {
      _showMessage('الرجاء تفعيل إذن الكاميرا من إعدادات الجهاز');
      openAppSettings();
    }
  }

  // ==================== عرض خيارات اختيار الصورة ====================

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'اختيار صورة الملف الشخصي',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Divider(),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('اختيار من المعرض'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('التقاط صورة بالكاميرا'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ==================== بناء قسم الصورة الشخصية ====================

  Widget _buildProfileImageSection() {
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_userAvatarUrl != null && _userAvatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_userAvatarUrl!);
    }

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Text(
                          _userName.isNotEmpty ? _userName[0] : 'م',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt,
                        size: 20, color: Colors.white),
                    onPressed: _showImagePickerOptions,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'اضغط لتغيير الصورة',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== عناصر واجهة المستخدم المساعدة ====================

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        subtitle: Text(
          value.isEmpty ? 'غير مضاف' : value,
          style: TextStyle(
            color: value.isEmpty ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        subtitle: Text(
          value.isEmpty ? 'غير مضاف' : value,
          style: TextStyle(
            color: value.isEmpty ? Colors.grey : Colors.black,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          color: AppColors.primary,
          onPressed: onEdit,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }

  // ==================== عرض رسالة ====================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==================== نافذة معلومات التطبيق ====================

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('عن التطبيق'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.business_center,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'تمام',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'تطبيق إدارة الشركة',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'الإصدار 1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'تم تطويره لتسهيل إدارة الشركات وتنظيم العمل بين الموظفين.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('سياسة الخصوصية'),
          content: const SingleChildScrollView(
            child: Text(
              'نحن في تطبيق تمام نلتزم بحماية خصوصية بياناتك.\n\n'
              '1. نقوم بجمع البيانات الأساسية فقط مثل الاسم والبريد الإلكتروني.\n'
              '2. لا نشارك بياناتك مع أي طرف ثالث.\n'
              '3. يمكنك طلب حذف بياناتك في أي وقت.\n'
              '4. نستخدم بياناتك فقط لتحسين تجربتك في التطبيق.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'owner':
        return 'مالك / مدير عام';
      case 'accountant':
        return 'محاسب';
      case 'member':
        return 'مهندس / عضو';
      default:
        return 'عضو';
    }
  }

  // ==================== بناء واجهة المستخدم الرئيسية ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الإعدادات الشخصية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveUserData,
            child: const Text(
              'حفظ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading && _userName.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // صورة الملف الشخصي
                  _buildProfileImageSection(),
                  const SizedBox(height: 24),

                  // ========== المعلومات الأساسية ==========
                  _buildSectionHeader('المعلومات الأساسية'),
                  const SizedBox(height: 16),

                  // البريد الإلكتروني (للقراءة فقط)
                  _buildReadOnlyField(
                    icon: Icons.email,
                    label: 'البريد الإلكتروني',
                    value: _userEmail,





                    
                  ),
                  const SizedBox(height: 12),

                  // الاسم الكامل
                  _buildEditableField(
                    icon: Icons.person,
                    label: 'الاسم الكامل',
                    value: _userName,
                    onEdit: () {
                      _showEditDialog(
                        title: 'تعديل الاسم الكامل',
                        currentValue: _userName,
                        onSave: (newValue) {
                          setState(() {
                            _nameController.text = newValue;
                            _userName = newValue;
                          });
                          _saveUserData();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // رقم الهاتف
                  _buildEditableField(
                    icon: Icons.phone,
                    label: 'رقم الهاتف',
                    value: _userPhone,
                    onEdit: () {
                      _showEditDialog(
                        title: 'تعديل رقم الهاتف',
                        currentValue: _userPhone,
                        onSave: (newValue) {
                          setState(() {
                            _phoneController.text = newValue;
                            _userPhone = newValue;
                          });
                          _saveUserData();
                        },
                        keyboardType: TextInputType.phone,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // العنوان
                  _buildEditableField(
                    icon: Icons.location_on,
                    label: 'العنوان',
                    value: _userAddress,
                    onEdit: () {
                      _showEditDialog(
                        title: 'تعديل العنوان',
                        currentValue: _userAddress,
                        onSave: (newValue) {
                          setState(() {
                            _addressController.text = newValue;
                            _userAddress = newValue;
                          });
                          _saveUserData();
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ========== المعلومات الوظيفية ==========
                  _buildSectionHeader('المعلومات الوظيفية'),
                  const SizedBox(height: 16),

// تاريخ التعيين
                  if (widget.currentUserRole == 'owner')
                    _buildEditableField(
                      icon: Icons.calendar_today,
                      label: 'تاريخ التعيين',
                      value: _userHireDate.isEmpty ? 'غير مضاف' : _userHireDate,
                      onEdit: _selectDate,
                    )
                  else
                    _buildReadOnlyField(
                      icon: Icons.calendar_today,
                      label: 'تاريخ التعيين',
                      value: _userHireDate.isEmpty ? 'غير مضاف' : _userHireDate,
                    ),
                  const SizedBox(height: 12),

// 🔥 مدة الخدمة 🔥
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.timeline, color: AppColors.primary),
                      title: const Text(
                        'مدة الخدمة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _serviceDuration,
                        style: TextStyle(
                          fontSize: 14,
                          color: _serviceDuration.contains('خطأ')
                              ? Colors.red
                              : AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // القسم
                  _buildEditableField(
                    icon: Icons.business,
                    label: 'القسم',
                    value: _userDepartment,
                    onEdit: () {
                      _showEditDialog(
                        title: 'تعديل القسم',
                        currentValue: _userDepartment,
                        onSave: (newValue) {
                          setState(() {
                            _departmentController.text = newValue;
                            _userDepartment = newValue;
                          });
                          _saveUserData();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // الوظيفة
                  _buildEditableField(
                    icon: Icons.work,
                    label: 'الوظيفة',
                    value: _userPosition,
                    onEdit: () {
                      _showEditDialog(
                        title: 'تعديل الوظيفة',
                        currentValue: _userPosition,
                        onSave: (newValue) {
                          setState(() {
                            _positionController.text = newValue;
                            _userPosition = newValue;
                          });
                          _saveUserData();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // رقم الطوارئ
                  _buildEditableField(
                    icon: Icons.emergency,
                    label: 'رقم الطوارئ',
                    value: _userEmergencyContact,
                    onEdit: () {
                      _showEditDialog(
                        title: 'تعديل رقم الطوارئ',
                        currentValue: _userEmergencyContact,
                        onSave: (newValue) {
                          setState(() {
                            _emergencyController.text = newValue;
                            _userEmergencyContact = newValue;
                          });
                          _saveUserData();
                        },
                        keyboardType: TextInputType.phone,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ========== الصلاحية ==========
                  _buildSectionHeader('الصلاحية'),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    icon: Icons.admin_panel_settings,
                    label: 'نوع الحساب',
                    value: _getRoleText(widget.currentUserRole),
                  ),

                  const SizedBox(height: 24),

                  // ========== الإشعارات ==========
                  _buildSectionHeader('الإشعارات'),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    icon: Icons.notifications,
                    title: 'تفعيل الإشعارات',
                    subtitle: 'استلام إشعارات حول المهام والتحديثات',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _showMessage('تم ${value ? "تفعيل" : "إيقاف"} الإشعارات');
                    },
                  ),

                  const SizedBox(height: 24),

                  // ========== معلومات التطبيق ==========
                  _buildSectionHeader('معلومات التطبيق'),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                    icon: Icons.info,
                    title: 'الإصدار',
                    subtitle: '1.0.0',
                  ),
                  _buildInfoTile(
                    icon: Icons.business_center,
                    title: 'عن التطبيق',
                    subtitle: 'اضغط للعرض',
                    onTap: _showAboutApp,
                  ),
                  _buildInfoTile(
                    icon: Icons.privacy_tip,
                    title: 'سياسة الخصوصية',
                    subtitle: 'اضغط للعرض',
                    onTap: _showPrivacyPolicy,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
