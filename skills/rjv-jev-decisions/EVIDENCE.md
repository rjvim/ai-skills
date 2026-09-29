# rjv-jev-decisions: evidence and ideas

Moved out of SKILL.md so agents do not load it every time.

## Evidence

- Built 2026-09-21 against the live TypeSafe docs (jev-1.13).
- Verified offline: request bodies match the documented API shape; the
  routing rules give the expected tier for confident, unsure and high-stakes
  answers; a missing key exits 3.
- Verified live on 2026-09-21 against jev-1.13.0, about 1 second per call
  end to end (first call about 2 seconds):
  - Model pick, 8 tasks. Tier was right on all 8: the lookup, rename and
    copy-a-pattern test went to haiku; the known-cause crash fix to sonnet;
    unknown-cause payout debugging, wallet schema design and a production
    delete migration to opus. The changelog summary was the only task
    offered a local model.
  - The first high-stakes wording scored 0.45 to 0.55 on harmless tasks
    (a read-only lookup that mentioned payouts, a rename, a UI fix). That
    pushed the lookup up to sonnet. The current wording, with criteria,
    scored those 0.07 to 0.34, while money, data, production and auth
    changes scored 0.9 or higher. Keep the criteria when you edit it.
  - Verify: a report that said "tests not added yet" scored 0.02 on the
    test item and escalated; the same report with a named passing test
    scored 0.9 and did not.
  - Build mode: a README typo scored below 0.05 everywhere; a Stripe refund
    webhook scored 0.9 or higher on four conditions, so gated.
- Hooks, verified live on 2026-09-22:
  - Claude Code: a general-purpose subagent spawned with no model got
    haiku from the hook, and the subagent reported running as Haiku 4.5.
  - Codex 0.155.1: with the hook enabled, a `fork_turns: "none"` sub-agent
    spawned with no model ran as gpt-5.6-luna at low effort, per its
    session record. The parent was gpt-5.6-sol.
  - Codex with the AGENTS.md rule: the parent ran the picker on the full
    brief and passed gpt-5.6-luna low itself; the hook logged it as an
    explicit model and left it alone.
  - Skips checked: explicit model, Explore agent type, Codex full-history
    fork, a non-spawn tool, and no key anywhere all leave the call as is.
- The thresholds (0.6, 0.5, 0.7) are still starting points. Ten tasks is
  a smoke test, not a benchmark. Log answers next to what each task really
  needed, then tune.
- Outside reports: a four-tier routing test measured about 0.65s and
  $0.000026 a call, all 40 calls routed correctly, and borderline middle-tier
  prompts came back at confidence 0.57–0.67. That is why low confidence
  moves up a tier here.

## Other decisions people give Jev in coding agents

Not built here. Candidates for the next question set:

- Tool-call gate: is this shell command destructive? (PreToolUse hook)
- Stop gate: does the transcript show the task finished? (Stop hook)
- Which skill fits this turn, or none? (TypeSafe skill-suggestion cookbook)
- Which files are relevant to this task, ranked by a per-file Noul.
- Which old tool outputs can be pruned from context.
