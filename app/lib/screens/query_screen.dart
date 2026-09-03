import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../api_client.dart';
import '../models/answer.dart';

class QueryScreen extends StatefulWidget {
  final ApiClient client;
  const QueryScreen({super.key, required this.client});

  @override
  State<QueryScreen> createState() => _QueryScreenState();
}

class _QueryScreenState extends State<QueryScreen> {
  final _controller = TextEditingController();
  Answer? _answer;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _answer = null;
    });
    try {
      final answer = await widget.client.query(q);
      setState(() => _answer = answer);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Evidence Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Ask a clinical question…',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: const Text('Search'),
              ),
            ]),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_answer != null)
              Expanded(
                child: ListView(children: [
                  MarkdownBody(data: _answer!.answer),
                  const Divider(height: 32),
                  ExpansionTile(
                    title: Text('Sources (${_answer!.sources.length})'),
                    children: _answer!.sources
                        .map((s) => ListTile(
                              title: Text('PubMed ID ${s.pubid}'),
                              subtitle: Text(
                                s.snippet,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                '${(s.similarity * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ))
                        .toList(),
                  ),
                ]),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'For research/educational purposes only. Not medical advice.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
