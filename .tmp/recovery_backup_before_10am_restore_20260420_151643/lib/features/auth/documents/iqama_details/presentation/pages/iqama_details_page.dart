import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';
import 'package:gaseel_courier/core/widgets/custom_text_form_field.dart';
import '../../../../../../core/profile/profile_service.dart';

class IqamaDetailsPage extends StatefulWidget {
  static const String id = '/signup/documents/iqama';
  const IqamaDetailsPage({super.key});

  @override
  State<IqamaDetailsPage> createState() => _IqamaDetailsPageState();
}

class _IqamaDetailsPageState extends State<IqamaDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _givenNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _dobController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  String? _gender;
  File? _photo;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _photo = File(pickedFile.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo of your Iqama')),
      );
      return;
    }

    await ProfileService.saveIqama(
      path: _photo!.path,
      givenName: _givenNameController.text.trim(),
      surname: _surnameController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _gender ?? '',
      number: _numberController.text.trim(),
      expiryDate: _expiryController.text.trim(),
    );

    if (mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Iqama',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[400]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Do not share this screenshot',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'This screenshot contains confidential information.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Photo Upload
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: _photo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_photo!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 40,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload Iqama Photo',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'Given name (English) *',
                hintText: 'Please fill in',
                controller: _givenNameController,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                fieldSpacing: 8,
                decoration: _inputDecoration(),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Surname (English) *',
                hintText: 'Please fill in',
                controller: _surnameController,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                fieldSpacing: 8,
                decoration: _inputDecoration(),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Date of birth *',
                hintText: 'Please select',
                controller: _dobController,
                readOnly: true,
                onTap: () => _pickDate(_dobController),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                fieldSpacing: 8,
                decoration: _inputDecoration(
                  hintText: 'Please select',
                  suffixIcon:
                      const Icon(Icons.calendar_today_outlined, size: 20),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              const Text(
                'Gender *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRadioButton('Male'),
                  const SizedBox(width: 16),
                  _buildRadioButton('Female'),
                ],
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'Iqama number *',
                hintText: 'Please fill in',
                controller: _numberController,
                keyboardType: TextInputType.number,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                fieldSpacing: 8,
                decoration: _inputDecoration(),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Expiry date *',
                hintText: 'Please select',
                controller: _expiryController,
                readOnly: true,
                onTap: () => _pickDate(_expiryController),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                fieldSpacing: 8,
                decoration: _inputDecoration(
                  hintText: 'Please select',
                  suffixIcon:
                      const Icon(Icons.calendar_today_outlined, size: 20),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Back',
                      onPressed: () => context.pop(),
                      variant: CustomButtonVariant.outlined,
                      height: 52,
                      borderRadius: 12,
                      foregroundColor: Colors.black,
                      borderSide: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Submit',
                      onPressed: _save,
                      height: 52,
                      borderRadius: 12,
                      backgroundColor: Colors.black,
                      foregroundColor: primaryColor,
                      elevation: 2,
                      shadowColor: Colors.black26,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
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

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText ?? 'Please fill in',
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => controller.text = date.toString().split(' ')[0]);
    }
  }

  Widget _buildRadioButton(String value) {
    final theme = Theme.of(context);
    final isSelected = _gender == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : Colors.grey[200]!,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: isSelected ? theme.colorScheme.primary : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
