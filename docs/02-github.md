# 02 — GitHub

Source control for the project. Repo: `ranjay24/devops-project` (private).

## Creating the repo

```
git init
gh repo create devops-project --private --source=. --remote=upstream
echo "# DevOps Project" > README.md
git add README.md
git commit -m "Add README.md project file"
git push -u upstream main
```

## Git 3-area flow (the mental model)

```
working dir ──git add──> staging ──git commit──> local repo ──git push──> GitHub
```

- `git add` = stage (choose files).
- `git commit` = snapshot with a message (local only).
- `git push` = upload commits to remote.
- `git pull` = download remote changes.
- `-u upstream` = set tracking so later pushes are just `git push`.

**Naming convention:** `origin` vs `upstream` — both are just names for remote repos. Convention: `origin` = your fork/main remote, `upstream` = the original project repo. (We used `upstream` for our main repo — slightly unusual, but consistent.)

## GitHub PAT (Personal Access Token) — CRITICAL lessons

A PAT is a **token instead of a password** for the GitHub API/git. It's scoped (you pick permissions) and revocable.

### The rule that got us in trouble

**NEVER put credentials in URLs:**
```
# BAD — leaks your token into bash history, logs, shell scripts:
git clone https://ranjay24:TOKEN@github.com/ranjay24/devops-project.git

# GOOD — let git prompt / use gh / use SSH keys:
git clone https://github.com/ranjay24/devops-project.git
```

### What happened (real demo, Trivy caught it)

Our Trivy scan of the home folder scanned `.bash_history` and found the PAT as a **CRITICAL** finding — the token we'd pasted in a `git clone` URL was stored in plaintext on the server. Anyone with access could read it and take over the repos.

**What we did (the correct incident response):**
1. **Revoked** the PAT on GitHub → Settings → Developer settings → Personal access tokens.
2. Created a **new** PAT (scope: repo contents).
3. Updated the **Jenkins credential** `github-credentials` with the new token.
4. Cleared the leak source: `history -c && rm -f ~/.bash_history`.

**Why `.bash_history` matters:** bash records every command you type into that file (plaintext, root-readable). Attackers steal history files to harvest credentials. Treat the server's history as sensitive.

### Storing tokens properly

- Jenkins **Credentials** store (`Manage Jenkins → Credentials`) — secret, encrypted, referenced by ID.
- The SonarQube token lives as a `Secret text` credential (`sonar-token`), the GitHub PAT as a `Username with password` credential (`github-credentials`).
- Rotate tokens whenever there's any chance of exposure.
