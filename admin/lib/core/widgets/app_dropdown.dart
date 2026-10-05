import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String? labelText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const AppDropdown({
    super.key,
    required this.value,
    this.labelText,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SizedBox(
      height: 44,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        dropdownColor: backgroundColor,
        icon: Icon(Icons.arrow_drop_down, size: 20, color: textSecondary),
        style: TextStyle(color: textPrimary, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          labelText: labelText,
          labelStyle: TextStyle(color: textSecondary, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary)),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
