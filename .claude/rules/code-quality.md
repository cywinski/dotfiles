---
paths: "**/*.py"
description: Code quality rules for Python
---

# Code Quality

- Make the SMALLEST reasonable changes to achieve the desired outcome.
- STRONGLY prefer simple, clean, maintainable solutions over clever or complex ones. Readability and maintainability are PRIMARY CONCERNS, even at the cost of conciseness or performance.
- WORK HARD to reduce code duplication, even if the refactoring takes extra effort.
- NEVER throw away or rewrite implementations without EXPLICIT permission. If considering this, STOP and ask first.
- Get approval before implementing ANY backward compatibility.
- Fix broken things immediately when you find them. Don't ask permission to fix bugs.

## Python Style
- Formatter: Ruff (line length: 88)
- Linter: Ruff check
- Type hints: Use for public APIs
- Docstrings: Google style
- Use Fire library instead of argparse
- All code files MUST start with a brief 2-line comment explaining what the file does. Each line MUST start with "ABOUTME: " to make them easily greppable.
