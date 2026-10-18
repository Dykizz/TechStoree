import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

class AppSearchField<T extends Object> extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final List<T> items;
  final bool Function(T item, String query) searchFilter;
  final String Function(T item) itemLabel;
  final String Function(T item)? itemSubtitle;
  final IconData? itemIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<T>? onSelected;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCleared;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.items,
    required this.searchFilter,
    required this.itemLabel,
    this.itemSubtitle,
    this.itemIcon = Icons.search_rounded,
    this.onChanged,
    this.onSelected,
    this.onSubmitted,
    this.onCleared,
  });

  @override
  State<AppSearchField<T>> createState() => _AppSearchFieldState<T>();
}

class _AppSearchFieldState<T extends Object> extends State<AppSearchField<T>> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return RawAutocomplete<T>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) {
          return const Iterable.empty();
        }
        return widget.items.where((item) => widget.searchFilter(item, query));
      },
      displayStringForOption: (T option) => widget.itemLabel(option),
      onSelected: (T option) {
        widget.controller.text = widget.itemLabel(option);
        if (widget.onSelected != null) {
          widget.onSelected!(option);
        }
      },
      fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: textCtrl,
          builder: (context, value, child) {
            return SizedBox(
              height: 34,
              child: TextFormField(
                controller: textCtrl,
                focusNode: focusNode,
                onChanged: (val) {
                  if (widget.onChanged != null) widget.onChanged!(val);
                },
                onFieldSubmitted: (val) {
                  onFieldSubmitted();
                  if (widget.onSubmitted != null) {
                    widget.onSubmitted!(val);
                  }
                },
                style: TextStyle(color: textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 12),
                  prefixIcon: Icon(widget.itemIcon ?? Icons.search_rounded, size: 16, color: textSecondary),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, size: 14, color: textSecondary),
                          onPressed: () {
                            textCtrl.clear();
                            if (widget.onCleared != null) widget.onCleared!();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            );
          },
        );
      },
      optionsViewBuilder: (context, onSelectedOption, Iterable<T> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: cardBg,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 360,
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelectedOption(option),
                    hoverColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.itemLabel(option),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.itemSubtitle != null && widget.itemSubtitle!(option).isNotEmpty)
                                  Text(
                                    widget.itemSubtitle!(option),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.north_west_rounded, size: 12, color: textSecondary.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
