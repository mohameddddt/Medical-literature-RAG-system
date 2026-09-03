import 'answer.dart';

/// One past search, stored locally so the user can revisit previous answers.
class SearchEntry {
  final String question;
  final DateTime timestamp;
  final Answer answer;

  const SearchEntry({
    required this.question,
    required this.timestamp,
    required this.answer,
  });

  factory SearchEntry.fromJson(Map<String, dynamic> json) => SearchEntry(
        question: json['question'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        answer: Answer.fromJson(
          (json['answer'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'timestamp': timestamp.toIso8601String(),
        'answer': answer.toJson(),
      };
}
