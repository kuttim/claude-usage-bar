# Claude Usage Bar

A macOS menu bar app showing your Claude 5-hour and weekly usage limits, with mini progress bars and a tick for how far through each time window you are.

Reads the Claude Code OAuth login from the macOS Keychain and polls the (undocumented) `api.anthropic.com/api/oauth/usage` endpoint every 60s.

```
swift build -c release && .build/release/ClaudeUsageBar
```
