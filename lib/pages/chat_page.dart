import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nova/models/chat_turn.dart';
import 'package:nova/services/chat_web_service.dart';
import 'package:nova/theme/colors.dart';
import 'package:nova/widgets/chat_turn_widget.dart';
import 'package:nova/widgets/search_bar_button.dart';
import 'package:nova/widgets/side_bar.dart';

class ChatPage extends StatefulWidget {
  final String question;
  const ChatPage({super.key, required this.question});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatTurn> _turns = [];
  final TextEditingController _followUpController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _searchSub;
  StreamSubscription? _contentSub;
  StreamSubscription? _isGeneratingSub;

  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    ChatWebService().connect();

    _searchSub = ChatWebService().searchResultStream.listen((data) {
      if (mounted && _turns.isNotEmpty) {
        setState(() {
          _turns.last.sources = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
        _scrollToBottom();
      }
    });

    _contentSub = ChatWebService().contentStream.listen((data) {
      if (mounted && _turns.isNotEmpty) {
        setState(() {
          _turns.last.answer += data['data'] ?? '';
          _turns.last.isGenerating = true;
        });
        _scrollToBottom();
      }
    });

    _isGeneratingSub = ChatWebService().isGeneratingStream.listen((generating) {
      if (mounted) {
        setState(() {
          _isGenerating = generating;
          if (_turns.isNotEmpty) {
            _turns.last.isGenerating = generating;
          }
        });
      }
    });

    // Start initial query
    _startNewQuery(widget.question);
  }

  @override
  void dispose() {
    _searchSub?.cancel();
    _contentSub?.cancel();
    _isGeneratingSub?.cancel();
    _followUpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startNewQuery(String query) {
    if (query.trim().isEmpty) return;

    final newTurn = ChatTurn(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: query,
      isGenerating: true,
    );

    setState(() {
      _turns.add(newTurn);
      _isGenerating = true;
    });

    _scrollToBottom();
    ChatWebService().chat(query);
  }

  void _submitFollowUp() {
    if (_isGenerating) {
      _stopGeneration();
      return;
    }

    final query = _followUpController.text.trim();
    if (query.isNotEmpty) {
      _followUpController.clear();
      _startNewQuery(query);
    }
  }

  void _stopGeneration() {
    ChatWebService().stopStream();
    if (mounted && _turns.isNotEmpty) {
      setState(() {
        _isGenerating = false;
        _turns.last.isGenerating = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                // Multi-Turn Chat Feed List
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _turns.map((turn) => ChatTurnWidget(turn: turn)).toList(),
                    ),
                  ),
                ),

                // Fixed Input Bar at Bottom
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
                              hintText: 'Ask follow-up or search anything...',
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

                              // Action Button: Stop (⏹️) when generating, Send (->) when idle
                              GestureDetector(
                                onTap: _submitFollowUp,
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: _isGenerating ? Colors.redAccent : AppColors.submitButton,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Icon(
                                    _isGenerating ? Icons.stop_rounded : Icons.arrow_forward,
                                    color: Colors.white,
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
