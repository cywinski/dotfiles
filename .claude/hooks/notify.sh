#!/usr/bin/env bash
# Send notifications when Claude Code needs attention.
# Terminal bell (propagates over SSH) + ntfy.sh push to phone.
# Used as a Notification hook.

MSG=$(jq -r '.notification // "Claude Code needs attention"')

# Terminal bell - flashes/bounces the local terminal even over SSH
printf '\a'

# Phone notification via ntfy.sh
curl -sf -d "$MSG" https://ntfy.sh/bcywinski-claude >/dev/null 2>&1

exit 0
