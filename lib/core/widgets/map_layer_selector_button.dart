import 'package:flutter/material.dart';
import '../../contracts/map_style.dart';
import '../theme/app_theme.dart';

/// Tombol floating elegan untuk beralih tipe lapisan peta.
class MapLayerSelectorButton extends StatelessWidget {
  final AppMapStyle currentStyle;
  final ValueChanged<AppMapStyle> onStyleChanged;

  const MapLayerSelectorButton({
    super.key,
    required this.currentStyle,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.layers_outlined, color: Colors.white, size: 22),
        tooltip: 'Pilih Gaya Peta (Satelit / 3D / Dark)',
        onPressed: () => _showStylePicker(context),
      ),
    );
  }

  void _showStylePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map, color: AppTheme.stravaOrange, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Pilih Tipe Lapisan Peta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...AppMapStyle.values.map((style) {
                  final isSelected = style == currentStyle;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.stravaOrange.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.stravaOrange
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        style.icon,
                        color: isSelected
                            ? AppTheme.stravaOrange
                            : AppTheme.textSecondary,
                      ),
                      title: Text(
                        style.displayName,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.stravaOrange
                              : AppTheme.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppTheme.stravaOrange, size: 20)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        onStyleChanged(style);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
