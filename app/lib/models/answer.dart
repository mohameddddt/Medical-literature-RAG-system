class Source {
  final String pubid;
  final double similarity;
  final String snippet;

  const Source({
    required this.pubid,
    required this.similarity,
    required this.snippet,
  });

  /// Public PubMed record for this abstract.
  String get pubmedUrl => 'https://pubmed.ncbi.nlm.nih.gov/$pubid/';

  String get similarityPercent => '${(similarity * 100).toStringAsFixed(1)}%';

  factory Source.fromJson(Map<String, dynamic> json) => Source(
        pubid: json['pubid'] as String? ?? 'unknown',
        similarity: (json['similarity'] as num?)?.toDouble() ?? 0,
        snippet: json['snippet'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'pubid': pubid,
        'similarity': similarity,
        'snippet': snippet,
      };
}

class Answer {
  final String answer;
  final List<Source> sources;

  const Answer({required this.answer, required this.sources});

  /// The model is prompted to append a fixed disclaimer. It is rendered
  /// separately in the UI, so strip it from the answer body to avoid showing
  /// the same sentence twice.
  String get body {
    const marker = 'Note: This is for research/educational purposes only';
    final index = answer.indexOf(marker);
    return index == -1 ? answer.trim() : answer.substring(0, index).trim();
  }

  /// Distinct PubMed IDs behind this answer, preserving retrieval order.
  List<String> get uniquePubIds {
    final seen = <String>{};
    return [
      for (final s in sources)
        if (seen.add(s.pubid)) s.pubid,
    ];
  }

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
        answer: json['answer'] as String? ?? '',
        sources: (json['sources'] as List? ?? [])
            .map((s) => Source.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'answer': answer,
        'sources': sources.map((s) => s.toJson()).toList(),
      };
}
