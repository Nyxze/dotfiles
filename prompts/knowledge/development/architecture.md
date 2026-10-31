# Architecture

- Keep module boundaries clear, with one concern per module and dependencies
  pointing one way.
- When a module exposes a new public API, offer a runnable example or demo
  before or right after implementation so the user can try its shape. Ask
  whether they want one; passing tests alone does not establish that the API
  feels right. The demo need not be permanent unless requested.
- Keep interfaces small. Split by concern instead of extending an interface
  that grows too broad.
- Treat files above roughly 500 lines as a sign to split responsibilities.
- Prefer an elegant, simple solution over a clever or exhaustive one. Ask when
  an architectural or naming choice is genuinely unclear.
