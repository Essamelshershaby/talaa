import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talaa/screens/login_screen.dart' show LoginScreen;
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../enums/user_role.dart';
import '../utils/app_colors.dart';
import '../screens/employees_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/invoices_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/placeholder_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _selectedDrawerIndex = 0;  // ← أضف هذا المتغير

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==================== الشريط العلوي ====================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('تمام', style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.primary,
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(widget.user.name, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Text(
                  widget.user.initials,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== القائمة الجانبية ====================
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // رأس القائمة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.user.initials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.user.role.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.email,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          
          // قائمة الخيارات
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // الرئيسية
                _buildDrawerItem(
                  Icons.dashboard,
                  'الرئيسية',
                  0,
                  DashboardScreen(user: widget.user),
                ),
                
                // خيارات المالك فقط
                if (widget.user.role == UserRole.owner) ...[
                  _buildDrawerItem(
                    Icons.people,
                    'إدارة الموظفين',
                    1,
                    EmployeesScreen(
                      currentUserUid: widget.user.uid,
                      currentUserRole: widget.user.role.toStorageString(),
                    ),
                  ),
                  _buildDrawerItem(
                    Icons.business,
                    'إدارة المشاريع',
                    2,
                    ProjectsScreen(
                      currentUserUid: widget.user.uid,
                      currentUserRole: widget.user.role.toStorageString(),
                    ),
                  ),
                  _buildDrawerItem(
                    Icons.receipt,
                    'الفواتير',
                    3,
                    InvoicesScreen(
                      currentUserUid: widget.user.uid,
                      currentUserRole: widget.user.role.toStorageString(),
                    ),
                  ),
                  _buildDrawerItem(
                    Icons.settings,
                    'الإعدادات',
                    4,
                    SettingsScreen(
                      currentUserUid: widget.user.uid,
                      currentUserRole: widget.user.role.toStorageString(),
                    ),
                  ),
                ],
                
                // خيارات المحاسب فقط
                if (widget.user.role == UserRole.accountant) ...[
                  _buildDrawerItem(
                    Icons.receipt,
                    'الفواتير',
                    1,
                    InvoicesScreen(
                      currentUserUid: widget.user.uid,
                      currentUserRole: widget.user.role.toStorageString(),
                    ),
                  ),
                  _buildDrawerItem(
                    Icons.payments,
                    'المدفوعات',
                    2,
                    const PlaceholderScreen(title: 'المدفوعات'),
                  ),
                  _buildDrawerItem(
                    Icons.settings,
                    'الإعدادات',
                    4,
                    SettingsScreen(
                      currentUserUid: widget.user.uid,
                      currentUserRole: widget.user.role.toStorageString(),
                    ),
                  ),

                ],
                
                // خيارات العضو فقط
                if (widget.user.role == UserRole.member) ...[
                  _buildDrawerItem(
                    Icons.task,
                    'مهامي',
                    1,
                    const PlaceholderScreen(title: 'مهامي'),
                  ),
                  _buildDrawerItem(
                    Icons.calendar_today,
                    'جدول الأعمال',
                    2,
                    const PlaceholderScreen(title: 'جدول الأعمال'),
                  ),
                ],
                
                const Divider(height: 24),
                
                // تسجيل الخروج
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥🔥🔥 هنا دالة _buildDrawerItem 🔥🔥🔥
  Widget _buildDrawerItem(IconData icon, String title, int index, Widget page) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedDrawerIndex == index ? AppColors.primary : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedDrawerIndex == index ? AppColors.primary : Colors.grey,
          fontWeight: _selectedDrawerIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedDrawerIndex == index,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedDrawerIndex = index;
        });
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => page,
          ),
        ).then((_) {
          setState(() {});
        });
      },
    );
  }

  // ==================== الشريط السفلي ====================
  Widget _buildBottomNavigationBar() {
  List<BottomNavigationBarItem> items = [];
  
  switch (widget.user.role) {
    case UserRole.owner:
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
        const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'الموظفين'),
        const BottomNavigationBarItem(icon: Icon(Icons.business), label: 'المشاريع'),
        const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
      ];
      break;
    case UserRole.accountant:
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
        const BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'الفواتير'),
        const BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'التقارير'),
      ];
      break;
    case UserRole.member:
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
        const BottomNavigationBarItem(icon: Icon(Icons.task), label: 'مهامي'),
        const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'جدول الأعمال'),
      ];
      break;
  }
  
  return BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: (index) {
      setState(() {
        _selectedIndex = index;
      });
      
      // 🔥 هنا نفتح الصفحات حسب الرقم المختار 🔥
      switch (widget.user.role) {
        case UserRole.owner:
          switch (index) {
            case 0:  // الرئيسية
              // إعادة تعيين الصفحة الحالية
              break;
            case 1:  // الموظفين
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeesScreen(
                    currentUserUid: widget.user.uid,
                    currentUserRole: widget.user.role.toStorageString(),
                  ),
                ),
              );
              break;
            case 2:  // المشاريع
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectsScreen(
                    currentUserUid: widget.user.uid,
                    currentUserRole: widget.user.role.toStorageString(),
                  ),
                ),
              );
              break;
            case 3:  // الإعدادات
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    currentUserUid: widget.user.uid,
                    currentUserRole: widget.user.role.toStorageString(),
                  ),
                ),
              );
              break;
          }
          break;
          
        case UserRole.accountant:
          switch (index) {
            case 0:  // الرئيسية
              break;
            case 1:  // الفواتير
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoicesScreen(
                    currentUserUid: widget.user.uid,
                    currentUserRole: widget.user.role.toStorageString(),
                  ),
                ),
              );
              break;
            case 2:  // التقارير
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaceholderScreen(title: 'التقارير المالية'),
                ),
              );
              break;
          }
          break;
          
        case UserRole.member:
          switch (index) {
            case 0:  // الرئيسية
              break;
            case 1:  // مهامي
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaceholderScreen(title: 'مهامي'),
                ),
              );
              break;
            case 2:  // جدول الأعمال
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaceholderScreen(title: 'جدول الأعمال'),
                ),
              );
              break;
          }
          break;
      }
    },
    items: items,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
  );
}
  // ==================== المحتوى الرئيسي ====================
  Widget _buildBody() {
    switch (widget.user.role) {
      case UserRole.owner:
        return _buildOwnerDashboard();
      case UserRole.accountant:
        return _buildAccountantDashboard();
      case UserRole.member:
        return _buildMemberDashboard();
    }
  }

  // ==================== لوحة المالك ====================
  Widget _buildOwnerDashboard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withOpacity(0.05), Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 16),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildSectionHeader('📁 المشاريع الأخيرة'),
          const SizedBox(height: 12),
          _buildProjectItem('تطبيق تمام', 'قيد التنفيذ', 75),
          _buildProjectItem('نظام إدارة الموظفين', 'مكتمل', 100),
          _buildProjectItem('تطبيق المحاسبة', 'قيد التنفيذ', 45),
          const SizedBox(height: 24),
          _buildSectionHeader('👥 آخر الموظفين'),
          const SizedBox(height: 12),
          _buildEmployeeItem('أحمد محمد', 'مهندس برمجيات'),
          _buildEmployeeItem('سارة علي', 'مصممة واجهات'),
          _buildEmployeeItem('محمد خالد', 'محاسب'),
        ],
      ),
    );
  }

  // ==================== لوحة المحاسب ====================
  Widget _buildAccountantDashboard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.withOpacity(0.05), Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 16),
          _buildFinancialStats(),
          const SizedBox(height: 24),
          _buildSectionHeader('💰 الفواتير غير المدفوعة'),
          const SizedBox(height: 12),
          _buildInvoiceItem('فاتورة #INV-001', '5,000 ₪', 'غير مدفوعة'),
          _buildInvoiceItem('فاتورة #INV-002', '12,500 ₪', 'غير مدفوعة'),
          _buildInvoiceItem('فاتورة #INV-003', '3,200 ₪', 'مدفوعة جزئياً'),
          const SizedBox(height: 24),
          _buildSectionHeader('📊 ملخص الشهر'),
          _buildSummaryCard(),
        ],
      ),
    );
  }

  // ==================== لوحة العضو ====================
  Widget _buildMemberDashboard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.orange.withOpacity(0.05), Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 16),
          _buildSectionHeader('✅ مهامي اليوم'),
          const SizedBox(height: 12),
          _buildTaskItem('مراجعة كود المشروع', 'قبل 3 ساعات', false),
          _buildTaskItem('اجتماع الفريق', 'بعد ساعة', false),
          _buildTaskItem('تحديث التقارير', 'غداً', true),
          const SizedBox(height: 24),
          _buildSectionHeader('📅 جدول الأعمال'),
          const SizedBox(height: 12),
          _buildEventItem('اجتماع أسبوعي', 'اليوم 10:00 صباحاً'),
          _buildEventItem('مراجعة المشروع', 'غداً 2:00 مساءً'),
          _buildEventItem('تسليم التقرير', 'الخميس 12:00 مساءً'),
        ],
      ),
    );
  }

  // ==================== عناصر واجهة المستخدم المساعدة ====================
  
  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحباً ${widget.user.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أهلاً بك في تطبيق تمام',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard('الموظفين', '24', Icons.people, AppColors.primary),
        _buildStatCard('المشاريع', '12', Icons.business, Colors.green),
        _buildStatCard('الإيرادات', '1.2M ₪', Icons.attach_money, Colors.orange),
        _buildStatCard('المصروفات', '450K ₪', Icons.shopping_cart, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const Spacer(),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard('الإيرادات', '1.2M ₪', Icons.trending_up, Colors.green),
        _buildStatCard('المصروفات', '450K ₪', Icons.trending_down, Colors.red),
        _buildStatCard('الضرائب', '120K ₪', Icons.account_balance, Colors.orange),
        _buildStatCard('الأرباح', '630K ₪', Icons.attach_money, AppColors.primary),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => _showMessage('عرض الكل'),
          child: const Text('عرض الكل'),
        ),
      ],
    );
  }

  Widget _buildProjectItem(String name, String status, int progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(Icons.business, color: AppColors.primary),
        ),
        title: Text(name),
        subtitle: Text(status),
        trailing: SizedBox(
          width: 50,
          child: Text('$progress%', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        onTap: () => _showMessage('فتح المشروع: $name'),
      ),
    );
  }

  Widget _buildEmployeeItem(String name, String position) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(name),
        subtitle: Text(position),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showMessage('عرض بيانات: $name'),
      ),
    );
  }

  Widget _buildInvoiceItem(String invoice, String amount, String status) {
    Color statusColor = status == 'غير مدفوعة' ? Colors.red : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.receipt, color: Colors.green),
        title: Text(invoice),
        subtitle: Text(amount),
        trailing: Chip(
          label: Text(status, style: const TextStyle(fontSize: 10)),
          backgroundColor: statusColor.withOpacity(0.2),
          labelStyle: TextStyle(color: statusColor),
        ),
        onTap: () => _showMessage('تفاصيل الفاتورة: $invoice'),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('إجمالي الإيرادات', '1,200,000 ₪'),
            const Divider(),
            _buildSummaryRow('إجمالي المصروفات', '450,000 ₪'),
            const Divider(),
            _buildSummaryRow('صافي الأرباح', '750,000 ₪', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: isBold ? Colors.black : Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.primary : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String task, String time, bool isCompleted) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) => _showMessage('تحديث حالة المهمة'),
          activeColor: Colors.orange,
        ),
        title: Text(task, style: TextStyle(decoration: isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Text(time),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildEventItem(String event, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.event, color: Colors.white, size: 20),
        ),
        title: Text(event),
        subtitle: Text(time),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showMessage('تفاصيل الحدث: $event'),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}