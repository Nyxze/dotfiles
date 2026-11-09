<!-- postman-cli:installation:start -->
Postman CLI is installed on this device, and can be used for API Engineering work.
<!-- postman-cli:installation:end -->

# Shared agent instructions

This is the shared instruction source for Codex, Claude Code, and OpenCode: each agent's entry file is a symlink to it,
managed by `managents`. Read the applicable project `AGENTS.md` and any instructions in the directories you work in, even
when the provider does not load that filename automatically. Project instructions specialize these defaults; current user
instructions take precedence over durable preferences.

Start at the [knowledge index](knowledge/INDEX.md) and open the owners relevant to the task. Relative links are relative
to `~/.agents/AGENTS.md`, not to the provider's entry file: resolve this file and installed skills to their real paths
before following them.

Write all artifacts in English. Reply in the user's language. Use short, technical prose; report the result and decisions
needed, without process narration, flattery, or apologies. When challenged, state the reasoning before revising it. Leave
user-owned decisions to the user.

Keep project constraints in the project's instructions. Record durable personal preferences in their existing knowledge
owner during the same task, never as conversation history. Keep model, permission, and feature settings in provider
configuration. Read [maintenance](knowledge/maintenance.md) before changing this system.

For machine changes, follow [managed configuration](knowledge/machine.md) and edit the repository source before
deploying. Never leave a live-only fix.

Prefer an existing personal skill when it fits. Prefer maintained scripts or CLIs for repeatable operations; turn a command
sequence needed twice into a script with explicit inputs and outputs.

Run local dev servers in my tmux session named after the repo (`tmux ls`), in a new `server` window — never as a preview/background process, and don't take over my existing nvim/terminal windows.
When you change code that a running local server serves, restart it in that `server` window (Ctrl-C, rerun the same command), wait until it's up and check the change is live before handing back. Skip it when no server is running or the change doesn't affect it (docs, tests only).
Before implementing anything, find the closest existing pattern in the repo (same kind of endpoint, store, test…), read it, and follow it: same structure, naming and idioms. Consistency beats a cleaner or more modern approach, because it keeps later refactoring easy; mention a better idea in one line instead of applying it. Only deviate to fix a real bug, and say so.
Don't write docs that copy code or describe how existing code works: they rot. Point to the files that hold the pattern, and only write down what the code can't tell (decisions, conventions, traps).
When you change what an endpoint accepts or returns, update its docs in the same change (swagger comments on the route, request and response; README or docs pages if they describe it).
When installing a package or tool (apt, go install, release binary…), run the commands in a dedicated tmux window of the repo's session (not via the Bash tool, not in my existing windows) and tell me which window it is, so I can validate it.
When writing Jira ticket content (new tickets, descriptions, edits): one plain-prose context sentence, then a short bullet list of what to do — readable in under 10s, no "Why:" / "What:" labels or headings.
For commit messages: stage the files first, then generate the subject with the local script `commit-msg` (it prints one line for the staged diff, with the ticket taken from the branch name, and doesn't commit) and commit with that line as is, no body. Don't write the message by hand. (Not applicable to the one-shot `claude -p` call made by that script itself: it just prints the line.)
`~/.agents` is my global context, loaded into every session: everything meant for AI agents lives there. Shared instructions go in `~/.agents/AGENTS.md`, skills in `~/.agents/skills`, knowledge in `~/.agents/docs`; never in a provider's own folder (`~/.claude`, `~/.codex`…) or in a repo. A skill that only one agent can use stays in that agent's own skills folder. `~/.agents` is a symlink to `.agents/` in my dotfiles repo, and the `managents` command (`managents setup`, `managents skills ls`, `managents skills promote NAME global`) manages it: run it instead of linking by hand.
My personal knowledge base is `~/.agents/docs` (a symlink to `~/work/docs`): one folder per repo, `<repo>/index.md` is the entry point and `<repo>/AGENTS.md` holds the agent notes. Read the page of the topic before acting, and use its scripts rather than retyping commands. A new personal procedure goes in a page there, with its scripts next to it, not in a repo and not in a skill.
