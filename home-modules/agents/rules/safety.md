# Safety

## Git

- Do not use destructive Git commands such as `git reset --hard`, `git clean -f`, force push, or `git stash`
  unless the user explicitly asks for them.
- Treat existing uncommitted changes as user work.
  Do not revert or overwrite them without explicit instruction.

## Sensitive Files

- Do not read or expose private keys, SSH config, GPG data, shell history, `.env` files, cloud credentials,
  GitHub auth files, or files under `secrets/` unless the user explicitly asks and the task requires it.
- Do not edit shell startup files, SSH/GPG config, GitHub auth config,
  or system directories such as `/etc`, `/usr`, `/var`, and `/boot` unless the user explicitly asks.
