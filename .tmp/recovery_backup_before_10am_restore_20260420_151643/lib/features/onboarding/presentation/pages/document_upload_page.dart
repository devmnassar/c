import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/profile/profile_service.dart';
import '../../../auth/sign_up/presentation/widgets/signup_scaffold.dart';

class DocumentUploadPage extends StatefulWidget {
  static const String id = '/signup/documents';
  const DocumentUploadPage({super.key});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final profile = await ProfileService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  bool _isDocumentCompleted(String type) {
    if (_profile == null) return false;
    switch (type) {
      case 'iqama':
        return _profile!['iqamaPath'] != null;
      case 'selfie':
        return _profile!['selfiePath'] != null;
      case 'license':
        return _profile!['licenseFrontPath'] != null;
      case 'registration':
        return _profile!['vehiclePath'] != null;
      case 'driver_card':
        return _profile!['driverCardPath'] != null;
      default:
        return false;
    }
  }

  void _navigateToDocument(String routePath) async {
    final result = await context.push(routePath);
    if (result == true) {
      _loadStatus();
    }
  }

  void _onNext() {
    final allDone =
        _isDocumentCompleted('iqama') &&
        _isDocumentCompleted('selfie') &&
        _isDocumentCompleted('license') &&
        _isDocumentCompleted('registration') &&
        _isDocumentCompleted('driver_card');

    if (allDone) {
      context.push('/signup/review');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SignupScaffold(
      title: 'Upload documents',
      currentStep: 3,
      totalSteps: 4,
      onNext: _onNext,
      body: Column(
        children: [
          _buildDocumentItem(
            'Iqama',
            'iqama',
            '/signup/documents/iqama',
            icon: Icons.badge_outlined,
          ),
          _buildDocumentItem(
            'Selfie',
            'selfie',
            '/signup/documents/selfie',
            icon: Icons.face_outlined,
          ),
          _buildDocumentItem(
            "Driver's licence",
            'license',
            '/signup/documents/license',
            icon: Icons.credit_card_outlined,
          ),
          _buildDocumentItem(
            'Vehicle registration',
            'registration',
            '/signup/documents/registration',
            icon: Icons.article_outlined,
          ),
          _buildDocumentItem(
            'Driver card',
            'driver_card',
            '/signup/documents/driver-card',
            icon: Icons.style_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
    String title,
    String type,
    String routeName, {
    required IconData icon,
  }) {
    final isDone = _isDocumentCompleted(type);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _navigateToDocument(routeName),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDone
                ? primaryColor.withValues(alpha: 0.08)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDone ? primaryColor : Colors.grey[400],
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF374151),
            letterSpacing: -0.3,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            isDone ? 'Completed' : 'Tap to upload',
            style: TextStyle(
              color: isDone ? primaryColor : Colors.grey[400],
              fontSize: 13,
              fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        trailing: Icon(
          isDone ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
          color: isDone ? primaryColor : Colors.grey[300],
          size: 24,
        ),
      ),
    );
  }
}
