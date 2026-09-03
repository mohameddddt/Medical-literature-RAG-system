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
});
