# Repository rulesets

This directory holds the GitHub ruleset definitions required by the Tenstorrent
Open Source Program Office (OSPO) for public repositories. Rulesets are not
applied automatically; a repository administrator applies them with the GitHub
CLI:

```bash
REPO=tenstorrent/tt-operator
gh api --method POST "repos/$REPO/rulesets" --input .github/rulesets/main-branch-protection.json
```

`main-branch-protection.json` targets the default branch (`~DEFAULT_BRANCH`) and:

- requires a pull request with at least one approving review before merging,
- restricts the merge method to squash only,
- blocks force pushes and branch deletion,
- allows Organization Admins and the `TT Repository Owner` custom role
  (role ID 53352) to bypass the review requirement for pull requests only.

If classic branch protection is still configured on the default branch, remove
it after the ruleset is active so the two do not overlap:

```bash
gh api --method DELETE "repos/$REPO/branches/main/protection"
```
