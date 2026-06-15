import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';

class BottomSheetOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  BottomSheetOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
  });
}

class CustomBottomSheets {
  CustomBottomSheets._();

  static Future<T?> showActionSheet<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required List<BottomSheetOption> options,
    bool isGrid = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: context.colors.surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetContext.colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: sheetContext.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: sheetContext.textTheme.bodySmall?.copyWith(
                          color: sheetContext.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                child: isGrid
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return InkWell(
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              option.onTap();
                            },
                            borderRadius: BorderRadius.circular(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: option.color ?? sheetContext.colors.primaryContainer,
                                  child: Icon(
                                    option.icon,
                                    color: option.color != null ? Colors.white : sheetContext.colors.onPrimaryContainer,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  option.title,
                                  style: sheetContext.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: options.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: option.color?.withAlpha((255 * 0.12).toInt()) ?? sheetContext.colors.primaryContainer,
                              child: Icon(
                                option.icon,
                                color: option.color ?? sheetContext.colors.primary,
                              ),
                            ),
                            title: Text(
                              option.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
                            trailing: Icon(
                              Icons.chevron_right,
                              color: sheetContext.colors.outline,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              option.onTap();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
