---
description: commit pending work and create or update a pull/merge request
---

you are running `/pr`.

`$ARGUMENTS` are extra instructions from the user. treat them as constraints on commit scope, base branch, title, body, draft state, labels, reviewers, or other PR/MR options.

## detect remote platform

check the remote URL to determine the platform:

```bash
git remote get-url origin
```

- if the remote contains `gitlab` → **GitLab**
- otherwise → **GitHub**

## workflow

1. run `/commit` first for any pending local changes
2. push the branch if needed without force

## check for existing PR/MR

before creating anything, check whether a PR/MR already exists for the current branch.

### GitHub

```bash
gh pr view --json number,url,title 2>/dev/null
```

- exit code 0 → PR **exists**
- non-zero → no PR for this branch

### GitLab

prefer the GitLab MCP if available — use MCP tools to list/search merge requests for the current branch.

if GitLab MCP is not available, fall back to:

```bash
glab mr view 2>/dev/null
```

- exit code 0 → MR **exists**
- non-zero → no MR for this branch

## if PR/MR exists → update description

draft an updated body from the full diff against the base branch and the commit history (same format you would use for a new PR/MR).

### GitHub

```bash
gh pr edit --body '<body>'
```

### GitLab

prefer the GitLab MCP if available — use MCP tools to update the merge request description.

if GitLab MCP is not available, fall back to:

```bash
glab mr update --description '<body>'
```

## if no PR/MR exists → create

### GitHub

use `gh pr create` to create the pull request.

### GitLab

prefer the GitLab MCP if available — use MCP tools for creating the merge request.

if GitLab MCP is not available, fall back to `glab mr create`.

## finish

return the PR/MR url.
