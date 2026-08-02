import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';

class LinkPreviewDialog {
  static void show(BuildContext context, String label, String url) {
    final cleanUrl = url.trim().isEmpty
        ? 'https://example.com'
        : (url.startsWith('http://') || url.startsWith('https://')
            ? url
            : 'https://$url');
    final domain = _extractDomain(cleanUrl);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Link Preview',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
        final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
        final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
        final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
        final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
        final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderClr, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge & Close
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: activeBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.language_rounded, size: 14, color: activeBlue),
                                const SizedBox(width: 6),
                                Text(
                                  domain.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: activeBlue,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: textTertiary),
                            onPressed: () => Navigator.of(ctx).pop(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Link Title / Label
                      Text(
                        label.isNotEmpty ? label : domain,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cleanUrl,
                        style: TextStyle(
                          fontSize: 12,
                          color: activeBlue,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),

                      // In-App Web View / Website Preview Frame
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF16191E) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderClr),
                          ),
                          child: Column(
                            children: [
                              // Browser Address Bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF22262F) : const Color(0xFFE5E7EB),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_outline, size: 12, color: textTertiary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        cleanUrl,
                                        style: TextStyle(fontSize: 11, color: textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.refresh, size: 14, color: textTertiary),
                                  ],
                                ),
                              ),
                              // Web Content Preview Placeholder / Frame
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: activeBlue.withValues(alpha: 0.1),
                                        ),
                                        child: Icon(
                                          Icons.public,
                                          size: 40,
                                          color: activeBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Web Preview for ${domain.toUpperCase()}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: Text(
                                          'Tap "Open Web View" below to view the site directly.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Toolbar
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: cleanUrl));
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied "$cleanUrl" to clipboard'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('Copy Link'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(color: borderClr),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: cleanUrl));
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening web link: $cleanUrl'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                Navigator.of(ctx).pop();
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Open Web View'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      if (host.isNotEmpty) {
        return host.startsWith('www.') ? host.substring(4) : host;
      }
    } catch (_) {}
    return 'Web Link';
  }
}
