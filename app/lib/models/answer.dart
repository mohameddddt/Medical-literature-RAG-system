class Source {
  final String pubid;
  final double similarity;
  final String snippet;

  const Source({
    required this.pubid,
    required this.similarity,
    required this.snippet,
  });

  factory Source.fromJson(Map<String, dynamic> json) => Source(
        pubid: json['pubid'] as String,
        similarity: (json['similarity'] as num).toDouble(),
        snippet: json['snippet'] as String,
      );
}

class Answer {
  final String answer;
  final List<Source> sources;

  const Answer({required this.answer, required this.sources});

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
        answer: json['answer'] as String,
        sources: (json['sources'] as List)
            .map((s) => Source.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
