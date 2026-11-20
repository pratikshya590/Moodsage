import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/primary_button.dart';

class PersonalizeProfileScreen extends StatefulWidget {
  const PersonalizeProfileScreen({super.key});

  @override
  State<PersonalizeProfileScreen> createState() =>
      _PersonalizeProfileScreenState();
}

class _PersonalizeProfileScreenState extends State<PersonalizeProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  Uint8List? _photoBytes; // the chosen photo
  String _photoType = 'image/jpeg';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      // Opens the gallery and shrinks the photo so it is small to store
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (picked == null) return; // user cancelled

      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _photoType = picked.mimeType ?? 'image/jpeg';
      });
    } catch (_) {
      _showError('Could not open your photos. Please try again.');
    }
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    // Turn the photo into text (base64) so it can be sent as JSON
    String? photoDataUrl;
    if (_photoBytes != null) {
      photoDataUrl = 'data:$_photoType;base64,${base64Encode(_photoBytes!)}';
      if (photoDataUrl.length > 900000) {
        _showError('That photo is too large. Please choose a smaller one.');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await ProfileService.instance.updateProfile(
        name: _nameCtrl.text.trim(),
        photoDataUrl: photoDataUrl,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const AppLogo(height: 150),
                  const SizedBox(height: 16),
                  Text(
                    'What should we\ncall you?',
                    style: AppTextStyles.heading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Let's make your Mental Wellness Companion\n"
                    'experience feel a little more personal',
                    style: AppTextStyles.greyBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Profile photo circle (tap to choose)
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF8FCF1),
                        border: Border.all(
                          color: AppColors.lightGreenBorder,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: _photoBytes != null
                            ? Image.memory(
                                _photoBytes!,
                                width: 130,
                                height: 130,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.account_circle,
                                size: 112,
                                color: AppColors.lightGreenBorder,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _photoBytes == null
                        ? 'Add a profile photo (optional)'
                        : 'Tap the photo to change it',
                    style: AppTextStyles.greyBody,
                  ),
                  const SizedBox(height: 28),

                  // "Your name"
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your name',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 40,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _continue(),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      counterText: '',
                      fillColor: const Color(0xFFF8F4F4),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: AppColors.mediumGreen,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AppColors.placeholder,
                          width: 1.2,
                        ),
                      ),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: 280,
                    child: PrimaryButton(
                      text: 'Continue',
                      onPressed: _continue,
                      isLoading: _saving,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}