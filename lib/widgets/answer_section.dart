import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nova/services/chat_web_service.dart';
import 'package:nova/theme/colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AnswerSection extends StatefulWidget {
  const AnswerSection({super.key});

  @override
  State<AnswerSection> createState() => _AnswerSectionState();
}

class _AnswerSectionState extends State<AnswerSection> {
  bool isLoading = true;
  String fullResponse = '';

  @override
  void initState() {
    super.initState();
    ChatWebService().queryStartStream.listen((_) {
      if (mounted) {
        setState(() {
          isLoading = true;
          fullResponse = "";
        });
      }
    });

    ChatWebService().contentStream.listen((data) {
      if (mounted) {
        setState(() {
          fullResponse += data['data'] ?? '';
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nova',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Skeletonizer(
          enabled: isLoading,
          child: isLoading && fullResponse.isEmpty
              ? Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              : Markdown(
                  data: fullResponse,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                    codeblockDecoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    code: const TextStyle(fontSize: 16),
                  ),
                ),
        ),
      ],
    );
  }
}
