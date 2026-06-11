// import 'package:flutter/material.dart';
// import 'package:gaseel_courier/core/locale/legacy_l10n_proxy.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../auth_i18n.dart';
// import '../../../../../core/auth/auth_service.dart';
// import '../../../../../core/profile/profile_service.dart';
// import '../../../../../core/widgets/custom_text_form_field.dart';

// class LoginPage extends StatefulWidget {
//   static const String id = '/login';
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleLogin() async {
//     final username = _usernameController.text.trim();
//     final password = _passwordController.text.trim();
//     final dynamic l10n = LegacyL10nProxy.of(context);

//     if (username.isEmpty) {
//       _showErrorSnackBar(l10n?.requiredField ?? 'This field is required');
//       return;
//     }

//     if (password.isEmpty) {
//       _showErrorSnackBar(l10n?.requiredField ?? 'This field is required');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     await Future.delayed(const Duration(seconds: 1));

//     if (mounted) {
//       await AuthService.login();

//       setState(() {
//         _isLoading = false;
//       });

//       context.go('/permissions');
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Theme.of(context).colorScheme.error,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dynamic l10n = LegacyL10nProxy.of(context);
//     final theme = Theme.of(context);
//     final primaryColor = theme.colorScheme.primary;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           Positioned(
//             top: -100,
//             right: -100,
//             child: Container(
//               width: 300,
//               height: 300,
//               decoration: BoxDecoration(
//                 color: primaryColor.withValues(alpha: 0.1),
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: -50,
//             left: -50,
//             child: Container(
//               width: 200,
//               height: 200,
//               decoration: BoxDecoration(
//                 color: primaryColor.withValues(alpha: 0.05),
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Center(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 32.0),
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 400),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         Center(
//                           child: Hero(
//                             tag: 'logo',
//                             child: Container(
//                               width: 100,
//                               height: 100,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 shape: BoxShape.circle,
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: primaryColor.withValues(alpha: 0.1),
//                                     blurRadius: 20,
//                                     offset: const Offset(0, 10),
//                                   ),
//                                 ],
//                               ),
//                               padding: const EdgeInsets.all(12),
//                               child: Image.asset(
//                                 'assets/images/logo.png',
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 32),
//                         Text(
//                           l10n?.companyName ?? 'Gaseel Express',
//                           style: const TextStyle(
//                             fontSize: 32,
//                             fontWeight: FontWeight.w900,
//                             letterSpacing: -1,
//                             color: Color(0xFF1F2937),
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           AppI18n.tr(
//                             context: context,
//                             en: 'Driver Portal',
//                             ar: 'بوابة السائق',
//                           ),
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.grey[500],
//                             fontWeight: FontWeight.w500,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 48),
//                         CustomTextField(
//                           label: AppI18n.tr(
//                             context: context,
//                             en: 'Username',
//                             ar: 'اسم المستخدم',
//                           ),
//                           hintText: AppI18n.tr(
//                             context: context,
//                             en: 'Enter your username',
//                             ar: 'أدخل اسم المستخدم',
//                           ),
//                           controller: _usernameController,
//                           prefixIcon: Icons.person_outline,
//                           textInputAction: TextInputAction.next,
//                           enabled: !_isLoading,
//                         ),
//                         const SizedBox(height: 24),
//                         CustomTextField(
//                           label: AppI18n.tr(
//                             context: context,
//                             en: 'Password',
//                             ar: 'كلمة المرور',
//                           ),
//                           hintText: AppI18n.tr(
//                             context: context,
//                             en: 'Enter your password',
//                             ar: 'أدخل كلمة المرور',
//                           ),
//                           controller: _passwordController,
//                           prefixIcon: Icons.lock_outline,
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _obscurePassword
//                                   ? Icons.visibility_outlined
//                                   : Icons.visibility_off_outlined,
//                               size: 20,
//                             ),
//                             onPressed: () => setState(
//                               () => _obscurePassword = !_obscurePassword,
//                             ),
//                           ),
//                           obscureText: _obscurePassword,
//                           textInputAction: TextInputAction.done,
//                           enabled: !_isLoading,
//                           onSubmitted: (_) => _handleLogin(),
//                         ),
//                         const SizedBox(height: 12),
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton(
//                             onPressed: () {},
//                             child: Text(
//                               AppI18n.tr(
//                                 context: context,
//                                 en: 'Forgot Password?',
//                                 ar: 'هل نسيت كلمة المرور؟',
//                               ),
//                               style: TextStyle(
//                                 color: primaryColor,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 13,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                         ElevatedButton(
//                           onPressed: _isLoading ? null : _handleLogin,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: primaryColor,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 20),
//                             elevation: 8,
//                             shadowColor: primaryColor.withValues(alpha: 0.4),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(18),
//                             ),
//                           ),
//                           child: _isLoading
//                               ? const SizedBox(
//                                   height: 24,
//                                   width: 24,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2.5,
//                                     valueColor: AlwaysStoppedAnimation<Color>(
//                                       Colors.white,
//                                     ),
//                                   ),
//                                 )
//                               : Text(
//                                   AppI18n.tr(
//                                     context: context,
//                                     en: 'Login',
//                                     ar: 'تسجيل الدخول',
//                                   ),
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                         ),
//                         const SizedBox(height: 32),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               AppI18n.tr(
//                                 context: context,
//                                 en: 'New to Gaseel?',
//                                 ar: 'جديد في غسيل؟',
//                               ),
//                               style: TextStyle(color: Colors.grey[600]),
//                             ),
//                             TextButton(
//                               onPressed: () async {
//                                 await ProfileService.clearProfile();
//                                 if (context.mounted) {
//                                   context.push('/signup');
//                                 }
//                               },
//                               child: Text(
//                                 AppI18n.tr(
//                                   context: context,
//                                   en: 'Create Account',
//                                   ar: 'إنشاء حساب',
//                                 ),
//                                 style: TextStyle(
//                                   color: primaryColor,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
