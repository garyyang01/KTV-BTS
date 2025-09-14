import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.emailAddress,
        hintText: AppLocalizations.of(context)!.emailAddressHint,
        prefixIcon: const Icon(Icons.email),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
      ),
      validator: validator ?? (value) => _defaultValidator(context, value),
      onChanged: onChanged,
    );
  }

  /// 預設的 Email 驗證器
  String? _defaultValidator(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.emailAddressRequired;
    }
    
    if (!EmailValidator.validate(value)) {
      return AppLocalizations.of(context)!.emailAddressInvalid;
    }
    
    return null;
  }
}
