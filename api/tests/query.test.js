import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { buildSystemPrompt, formatContext } from '../src/prompt.js';

describe('prompt', () => {
  it('buildSystemPrompt returns a non-empty string', () => {
    assert.ok(buildSystemPrompt().length > 0);
  });

  it('formatContext numbers passages and includes pubid', () => {
    const passages = [
      { pubid: '11111', content: 'Statins reduce LDL cholesterol.' },
      { pubid: '22222', content: 'Beta blockers lower heart rate.' },
    ];
    const ctx = formatContext(passages);
    assert.ok(ctx.includes('[1]'));
    assert.ok(ctx.includes('[2]'));
    assert.ok(ctx.includes('11111'));
    assert.ok(ctx.includes('22222'));
  });

  it('omits the verdict instruction by default', () => {
    assert.ok(!buildSystemPrompt().includes('ANSWER: yes'));
    assert.ok(!buildSystemPrompt({ requireVerdict: false }).includes('ANSWER: yes'));
  });

  it('adds the verdict instruction when requested', () => {
    const prompt = buildSystemPrompt({ requireVerdict: true });
    assert.ok(prompt.includes('ANSWER: yes'));
    assert.ok(prompt.includes('ANSWER: maybe'));
  });

  it('keeps the citation and disclaimer rules in both modes', () => {
    for (const prompt of [
      buildSystemPrompt(),
      buildSystemPrompt({ requireVerdict: true }),
    ]) {
      assert.ok(prompt.includes('Cite every claim'));
      assert.ok(prompt.includes('not medical advice'));
    }
  });
});
