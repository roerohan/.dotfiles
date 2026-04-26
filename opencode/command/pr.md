---
description: commit pending work and create a pull/merge request
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

## create the PR/MR

### GitHub

use `gh pr create` to create the pull request.

### GitLab

prefer the GitLab MCP if available — use MCP tools for creating the merge request.

if GitLab MCP is not available, fall back to `glab mr create`.

## finish

return the PR/MR url.
