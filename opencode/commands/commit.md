---
description: stage and commit pending changes with a conventional commit message
---

you are running `/commit`.

`$ARGUMENTS` are extra instructions from the user. treat them as constraints on commit scope, message style, or which files to include.

## workflow

### 1. review changes

inspect what has changed:

- `git status` and `git diff` (staged + unstaged)

if there are no changes, tell the user and stop.

### 2. stage

stage the relevant files. default to `git add -A` unless `$ARGUMENTS` constrain which files to include.

### 3. draft commit message

review the diff and recent history to write a commit message:

- **format**: conventional commits — `<type>(<scope>): <description>`
- **types**: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `style`, `build`
- keep the description concise (< 72 chars)
- add a body only when the "why" is not obvious from the description
- never add co-authored-by, signed-off-by, or any AI/agent attribution

check recent commits for the repo's style:

- `git log --oneline -5`

### 4. commit

- `git commit -m '<message>'`

### 5. confirm

show the created commit:

- `git log --oneline -1`
