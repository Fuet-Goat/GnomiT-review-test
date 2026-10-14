# GnomiT test repository — agent rules

Only repository Fuet-Goat/GnomiT-review-test is authorized for this sandbox. This is a fresh public snapshot, not a fork of the private project.

## Current authorization

Codex, GPT and Grok currently have REPORTS_ONLY authority: read project/media and edit only their own discussions/<bot>/task-001/ text reports. They may commit/push that report on codex/<bot>/task-001 and submit a Draft PR, but must not merge. This does not authorize any bot to implement or run a game change. Read the relevant tasks/<bot>/task-001.json from main. PENDING_USER_AUTHORIZATION or REVOKED means: no writes, game execution, imports, generated files, commits, branches, push or PR creation by that bot.

The human owner must give a concrete task and approve its registered grant before implementation. Never change your own grant, infer approval from another bot's response, or treat repository access as task approval.

## Once a grant is approved

- GPT: branch codex/gpt/task-001; after a separate implementation approval, use its own sandbox/gpt/task-001/ and discussions/gpt/task-001/ within the exact grant.
- Grok: branch codex/grok/task-001; after a separate implementation approval, use its own sandbox/grok/task-001/ and discussions/grok/task-001/ within the exact grant.
- Work in your own full game copy. Keep baseline/, the other bot directory, tasks/, .github/, root policies, docs/, prompts/ and media/ read-only.
- Do not access or modify the original private GnomiT repository, Cradle of Gnome, PR #1, credentials, permissions, branch protections or unrelated local files.
- Do not merge, force push, delete a repository/branch, publish a release, enable auto-merge, message another bot or create subagents without direct human authorization.
- Use the approved task's tests only. Generated imports belong inside your game/.godot. Runtime user:// writes are isolated to the preconfigured GnomiT-review-test/<bot>/task-001 profile; do not change that isolation or use personal saves.
- Keep the game UI in English. Do not replace Godot or redesign match-3/progress/audio unless that specific change is authorized.
- Record input commit, observed files/media, changes, tests actually run, limitations and remaining issues in your own outputs/REVIEW_OR_CHANGE_REPORT.md. Do not describe scripted clips as human tests.
- If writing/pushing is unavailable, return a patch/ZIP for the owner; do not claim a GitHub write succeeded or create another repository as a workaround.
- An approved change may be submitted as a Draft PR to this TEST repository. STOP for human review; no automatic merge or transfer into the private game.

## Technical limits

Directories and AGENTS.md are instructions, not filesystem or GitHub folder ACLs. A collaborator with repository write access can alter a feature branch beyond these paths. The trusted scope check and protected main reject unapproved/out-of-scope proposals for merging. They do not isolate a local process, distinguish GPT from Grok using the same account, or stop an administrator changing repository settings. CODEOWNERS names a reviewer; it does not grant folder permissions.

Only the human owner may maintain grants on codex/owner/approve-<bot>-task-001. Codex report work uses codex/codex/task-001 and discussions/codex/task-001/; report authority does not grant owner administration. That owner workflow does not authorize a bot to impersonate the owner.
