import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/auth/auth_service.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';
import 'package:gaseel_courier/features/auth/documents/document_upload/presentation/pages/document_upload_page.dart';

class WelcomePage extends StatelessWidget {
  static const String id = '/signup/welcome';

  const WelcomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    Navigator.of(context).pop();
    await AuthService.logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    const drawerColor = Color(0xFF001820);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.86,
      backgroundColor: drawerColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 22),
            const CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xFF28C7BE),
              child: Icon(Icons.person, size: 46, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(
              'Courier',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        'SAR 0.00',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Income',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '0',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Orders',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Divider(color: Color(0xFF29424A), height: 1),
            const Spacer(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              leading: const Icon(Icons.logout, color: Colors.white),
              title: Text(
                'Logout',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF3F4F6);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          Expanded(
            flex: 56,
            child: Container(
              width: double.infinity,
              color: primaryColor,
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(
                            Icons.menu,
                            size: 28,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Hero(
                        tag: 'logo',
                        child: Container(
                          width: 126,
                          height: 126,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 44,
            child: Container(
              width: double.infinity,
              color: backgroundColor,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 34, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Ready to join Gaseel Express?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            letterSpacing: -0.6,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Start your courier registration by tapping\n'
                          'the button below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            height: 1.35,
                          ),
                        ),
                        const Spacer(),
                        CustomButton(
                          text: 'Continue',
                          fullWidth: true,
                          onPressed: () => context.go(DocumentUploadPage.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
