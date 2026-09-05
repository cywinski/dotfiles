# Agent configuration

Run `bash setup.sh` to install Claude Code settings and shared Codex guidance.
Run `bash setup-codex.sh` to install only Codex's instruction and skill links.
Both scripts preserve replaced files as backups.

| Edit here | Claude Code reads | Codex reads |
| --- | --- | --- |
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| `.claude/skills/<name>/` | `~/.claude/skills/<name>/` | `~/.agents/skills/<name>/` |
| `.claude/commands/` | Claude slash commands | `.codex/skills/` wrappers linked under `~/.agents/skills/` |

Rerun setup after adding a skill. Existing linked skills update immediately
when their source changes; start a fresh session to reload global instructions.
The links depend on keeping this checkout available at its installed path.

Project instructions and skills belong in each project repository. For
midtraining-generalisation, `AGENTS.md` links to `CLAUDE.md`, and
`.agents/skills/` links to `.claude/skills/`.

Claude settings, permissions, plugins, and scheduled tasks remain specific to
Claude. Codex's `config.toml`, connections, and permissions are managed separately.
The setup scripts do not copy credentials or Claude permissions into Codex.

For an isolated installation check, run `bash setup-codex.sh /tmp/agent-profile`.
