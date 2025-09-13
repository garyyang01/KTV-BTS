import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

/// 電子郵件輸入組件
/// 包含 Email 格式驗證功能
class EmailInput extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const EmailInput({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email address',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      validator: validator ?? _defaultValidator,
      onChanged: onChanged,
    );
  }

  /// 預設的 Email 驗證器
  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }
    
    if (!EmailValidator.validate(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
}
