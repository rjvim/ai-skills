---
name: rjv-github-image-upload
description: "Upload local images to GitHub and embed them in a PR/issue/comment as canonical github.com/user-attachments URLs (private repos stay private), via the gh-image CLI. Triggers: 'attach a screenshot to the PR', 'add an image to the PR/issue', 'show test results in the PR', 'embed before/after screenshots'."
license: MIT
---

# Upload images to GitHub (gh-image)

GitHub has **no public API** for image uploads. [`gh-image`](https://github.com/drogers0/gh-image)
(MIT, © drogers0) replicates the web UI's flow as a `gh` extension and prints a ready-to-embed
`![name](url)` with a `user-attachments` URL scoped to the repo's visibility.

**The user only sees a screenshot once it is uploaded and linked.** An image you opened with
Read is visible to you alone. Never report "see the screenshot" for one you did not upload.

## Step 1 — Upload

Use an absolute path, quoted (CleanShot names contain narrow spaces).

```bash
# One or more images; --repo is optional inside a repo working dir.
gh image "/abs/path/screenshot.png" --repo <owner>/<repo>
```

It prints one markdown line per image to stdout. Capture it.

## Step 2 — Embed into the PR / issue / comment

**Append to a PR description** (preserves the existing body):

```bash
MD="$(gh image "/abs/path/shot.png" --repo owner/repo)"
BODY="$(gh pr view <pr> --repo owner/repo --json body -q .body)"
printf '%s\n\n## Screenshots\n\n%s\n' "$BODY" "$MD" \
  | gh pr edit <pr> --repo owner/repo --body-file -
```

**Post as a new PR comment:**

```bash
MD="$(gh image "/abs/path/shot.png" --repo owner/repo)"
printf '## Screenshots\n\n%s\n' "$MD" | gh pr comment <pr> --repo owner/repo --body-file -
```

**Issue body / comment:** same pattern with `gh issue edit <n>` or `gh issue comment <n>`.

Always use `--body-file -`, never inline `--body`, so multi-line bodies can't break quoting.

To control display size, embed `<img width="800" alt="screenshot" src="<url>" />` instead.

## Step 3 — Verify

```bash
gh pr view <pr> --repo owner/repo --json body -q .body   # confirm the URL is present
```

On a private repo an anonymous fetch of the URL returns 404/403. That is expected.

## If the upload fails

| Symptom | Fix |
|---|---|
| `<org> enforces SAML SSO and your session is not authorized…` | Ask the user to open `https://github.com/orgs/<org>/sso` and authorize (lasts ~24h), then retry. |
| `uploadToken not found … do you have write access?` | Confirm write access; if the org uses SSO, authorize as above. |
| No `user_session` cookie found | The upload uses the browser's GitHub cookie, not the `gh` token. Ask the user to log into GitHub in Chrome or Safari. On first read, macOS shows a Keychain prompt: **Always Allow**. |
| `unknown command "image"` | `gh extension install drogers0/gh-image` |
| `gh` not logged in | Ask the user to run `gh auth login`. Never run it unattended. |

The `user_session` cookie grants full account access. Never print or copy it.
