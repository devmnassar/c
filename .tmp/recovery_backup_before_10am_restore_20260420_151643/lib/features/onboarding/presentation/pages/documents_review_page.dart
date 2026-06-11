import 'package:flutter/material.dart';
import '../../../../core/profile/profile_service.dart';
import 'package:go_router/go_router.dart';

class DocumentsReviewPage extends StatefulWidget {
  static const String id = '/signup/review';
  const DocumentsReviewPage({super.key});

  @override
  State<DocumentsReviewPage> createState() => _DocumentsReviewPageState();
}

class _DocumentsReviewPageState extends State<DocumentsReviewPage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  void _onSubmit() async {
    setState(() => _loading = true);
    // Mock final submission
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      context.go('/signup/awaiting-review');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ScaffoldItem(
      title: 'Review Information',
      currentStep: 4,
      totalSteps: 4,
      onNext: _onSubmit,
      nextLabel: 'Submit for Approval',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Please make sure all information matches your documents.',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildReviewItem('Iqama Number', _profile?['iqamaNumber'] ?? 'N/A'),
          _buildReviewItem(
            "Driver's Licence",
            _profile?['licenseNumber'] ?? 'N/A',
          ),
          _buildReviewItem(
            'Plate Number',
            _profile?['vehiclePlateNumber'] ?? 'N/A',
          ),
          _buildReviewItem('Date of Birth', _profile?['iqamaDob'] ?? 'N/A'),
          _buildReviewItem('Gender', _profile?['iqamaGender'] ?? 'N/A'),
          const SizedBox(height: 16),
          Text(
            'By submitting, you agree to our terms and conditions.',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
