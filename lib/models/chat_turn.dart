class ChatTurn {
  final String id;
  final String question;
  List<Map<String, dynamic>> sources;
  String answer;
  bool isGenerating;

  ChatTurn({
    required this.id,
    required this.question,
    List<Map<String, dynamic>>? sources,
    this.answer = '',
    this.isGenerating = true,
  }) : sources = sources ?? [];
}
