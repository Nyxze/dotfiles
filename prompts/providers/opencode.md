# OpenCode

Use the [resource guide](../README.md) for installation and checks.

| Resource | Destination |
| --- | --- |
| Global instructions | `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/AGENTS.md` |
| Personal skills | `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/NAME` |

The native global directory is under the XDG config home, not `~/.opencode`.
Check the installed binary with `opencode debug paths`. An `OPENCODE_CONFIG_DIR`
is an additional configuration source, not a replacement for the XDG target
managed here. See the [configuration guide](https://opencode.ai/docs/config/).

OpenCode 1 also discovers skills in Claude-compatible and agent-compatible
locations. Native links keep this installation independent of those locations;
all managed aliases resolve to the same source. Inspect `opencode debug skill`
for the winning name and path. See [skill discovery](https://opencode.ai/docs/skills/).

Its native global `AGENTS.md` takes precedence over the Claude global fallback.
At project scope it prefers `AGENTS.md` over `CLAUDE.md`. Ordinary Markdown links
do not automatically inject their targets; the shared entry point directs the
agent to read relevant owners. See [instruction discovery](https://opencode.ai/docs/rules/).

Run diagnostics from the intended project with the launch environment in place.
Compatibility flags, extra config, and plugins can change what the session sees.
These notes describe OpenCode 1; recheck native diagnostics and documentation
before applying them to another major version.

Native agents are not translated from Claude definitions. Model names, tools,
and permissions belong in OpenCode configuration. Old empty `agent/` directories
or `.generated-from-prompts` markers can remain; the installer does not alter them
or any user-written agent files.
