import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nova/services/chat_web_service.dart';
import 'package:nova/theme/colors.dart';
import 'package:nova/widgets/answer_section.dart';
import 'package:nova/widgets/search_bar_button.dart';
import 'package:nova/widgets/side_bar.dart';
import 'package:nova/widgets/sources_section.dart';

class ChatPage extends StatefulWidget {
  final String question;
  const ChatPage({super.key, required this.question});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String currentQuestion;
  final TextEditingController _followUpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentQuestion = widget.question;
    ChatWebService().connect();
    ChatWebService().chat(currentQuestion);
  }

  @override
  void dispose() {
    _followUpController.dispose();
    super.dispose();
  }

  void _submitFollowUp() {
    final query = _followUpController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        currentQuestion = query;
      });
      _followUpController.clear();
      ChatWebService().chat(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          kIsWeb ? const SideBar() : const SizedBox(),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentQuestion,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const SourcesSection(),
                          const SizedBox(height: 24),
                          const AnswerSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Exact Same Search Bar UI as HomePage
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: Container(
                    width: 700,
                    decoration: BoxDecoration(
                      color: AppColors.searchBar,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.searchBarBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _followUpController,
                            onSubmitted: (_) => _submitFollowUp(),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'Search anything...',
                              hintStyle: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              const SearchBarButton(
                                icon: Icons.auto_awesome_outlined,
                                text: 'Focus',
                              ),
                              const SearchBarButton(
                                icon: Icons.add_circle_outline_outlined,
                                text: 'Attach',
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _submitFollowUp,
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: AppColors.submitButton,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.background,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
