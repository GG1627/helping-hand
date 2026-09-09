# AI Usage Policy — CEN 4907/8C (Senior Design)

Full course policy: /ai-policy/ai-usage-policy.pdf

## Rules for any AI agent working in this repo

1. **Disclosure is mandatory, no exceptions, no size threshold.** Every commit
   that includes AI-generated or AI-modified content must include a trailer:

       AI-Assisted: <tool-name>

   e.g. `AI-Assisted: codex` or `AI-Assisted: claude-code`. Use your own
   identity — do not omit this because a change felt small. Per policy,
   *any* undisclosed use is academic dishonesty.

2. **Never commit unreviewed work.** Stage changes only after the student has
   explicitly reviewed them in this session. Do not auto-commit or batch-commit
   without a human checkpoint.

3. **Approved tools only.** Currently authorized: Codex, Claude Code. Do not
   invoke or suggest any other external AI tool/API without the student
   confirming instructor approval first.

4. **No silent complexity.** For non-trivial logic (ML pipeline, BLE, Flutter/
   Firebase glue), flag it explicitly and prompt the student to walk through
   it before committing — inability to explain submitted code is grounds for
   a zero, so this isn't optional politeness, it's a required checkpoint.

Team AI-usage consensus is documented separately in /ai-policy/TEAM-CONSENSUS.md
— not an agent instruction, that's a human agreement record.