# Tooling

Preferred tools on this machine.
Use these from the start instead of discovering them via denied commands.

## Python

- Use `uv` exclusively: `uv add` / `uv remove` for dependencies, `uv run` to execute, `uv sync` to install.
- Do not invoke `python` / `python3` directly;
  run the interpreter via `uv run python` (and scripts via `uv run <script>`).
- For a CLI tool available on PyPI, first check whether it is installed locally (e.g. `command -v <tool>`);
  use it directly if present, and only fall back to `uvx <tool>` if it is not. Do not install it.
- Never use `pip`, `pip3`, `python -m pip`, or `uv pip`; they are all denied by permissions.

## Rust

- Use `cargo add` / `cargo remove` to manage dependencies in `Cargo.toml`.

## Dependency files

- Do not directly edit the dependency sections of `pyproject.toml`, `Cargo.toml`, or similar manifest files
  (e.g. adding, removing, or changing a version).
- Always go through the package manager's command (`uv add` / `uv remove`, `cargo add` / `cargo remove`,
  etc.) so the lockfile stays in sync.
- Editing these files directly for non-dependency changes (e.g. project metadata, build settings) is fine.

## Git hooks

- The hook runner is `prek` (pre-commit compatible), not `pre-commit`.
- Run hooks with `prek run` (e.g. `prek run --files <paths>`).
