# Catalyst

Ticket orchestration pattern for coding agents — fan out, reduce, verify, synthesize.

## Installation

### From GitHub (recommended)

```bash
# Add the marketplace
/plugin marketplace add {org}/catalyst

# Install the plugin
/plugin install catalyst@catalyst-marketplace
```

### From local repository

```bash
# Clone the repo
git clone https://github.com/{org}/catalyst.git ~/.claude/plugins/catalyst

# Add as local marketplace
/plugin marketplace add ~/.claude/plugins/catalyst

# Install
/plugin install catalyst@catalyst-marketplace
```

### Direct local testing

```bash
claude --plugin-dir /path/to/catalyst
```

## Usage

Once installed, use the `/catalyst` command with a ticket description:

```
/catalyst Fix the login timeout bug
```

The plugin provides:

- **Skills**: `bug-fix`, `code-review`, `feature-implementation`
- **Commands**: `/catalyst`, `/catalyst-install`, `/add-skill`, `/add-template`, `/build-catalyst`, `/catalyst-testcases`, `/learn`
- **Agents**: `catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, `catalyst-synthesizer`, `catalyst-code-reviewer`

## Updating

```bash
/plugin update catalyst@catalyst-marketplace
```

## License

MIT
