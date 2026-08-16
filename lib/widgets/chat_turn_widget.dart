import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nova/models/chat_turn.dart';
import 'package:nova/theme/colors.dart';
import 'package:nova/widgets/code_block_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatTurnWidget extends StatelessWidget {
  final ChatTurn turn;

  const ChatTurnWidget({super.key, required this.turn});

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching url: $e");
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareAnswer(String text) {
    if (text.isEmpty) return;
    Share.share(text, subject: 'Nova AI Answer');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Question Title
        Text(
          turn.question,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),

        // 2. Sources Section
        if (turn.isGenerating && turn.sources.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.source_outlined, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    "Sources",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Skeletonizer(
                enabled: true,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 140,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          )
        else if (turn.sources.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.source_outlined, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    "Sources",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: turn.sources.map((res) {
                  final String url = res['url'] ?? '';
                  final String title = res['title'] ?? '';

                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _launchURL(url),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white10,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              url,
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),

        // 3. Nova AI Answer Header & Markdown Body (Selectable Text & 1-Tap Copy Code Blocks)
        const Text(
          'Nova',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Skeletonizer(
          enabled: turn.isGenerating && turn.answer.isEmpty,
          child: turn.isGenerating && turn.answer.isEmpty
              ? Container(
                  height: 90,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              : MarkdownBody(
                  data: turn.answer,
                  selectable: true,
                  builders: {
                    'code': CodeElementBuilder(),
                  },
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                    codeblockDecoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    code: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
        ),

        // 4. Action Buttons (Copy Full Answer, Share Answer)
        if (turn.answer.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _copyToClipboard(context, turn.answer),
                icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                label: const Text(
                  'Copy Answer',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.cardColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _shareAnswer(turn.answer),
                icon: const Icon(Icons.share_outlined, size: 16, color: Colors.white70),
                label: const Text(
                  'Share',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.cardColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 40),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 40),
      ],
    );
  }
}
