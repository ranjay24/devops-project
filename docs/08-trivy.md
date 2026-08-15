# 08 — Trivy (security scanning)

Aqua Trivy scans for **vulnerabilities (CVEs), secrets, and misconfigurations**. Installed at `/usr/local/bin/trivy` (v0.73.0, via Aqua install.sh).

## What the flags mean

```
trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 .
```

| Flag | Meaning |
|---|---|
| `fs` | scan a **filesystem** (vs `image` for a container image) |
| `--scanners vuln,secret,misconfig` | CVEs + leaked secrets + bad configs |
| `--severity HIGH,CRITICAL` | only report serious stuff |
| `--ignore-unfixed` | skip issues with **no fix available yet** (noise) |
| `--exit-code 1` | exit 1 when findings exist at the given severity → `sh` fails → **build aborts** (security gate) |
| `.` | scan the current directory (Jenkins workspace) |

## The pipeline stage (added to Jenkinsfile)

```groovy
stage('Trivy FS Scan') {
    steps {
        sh '/usr/local/bin/trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 .'
    }
}
```

- Full path `/usr/local/bin/trivy` — the Jenkins service PATH may not include `/usr/local/bin`.
- No `sudo` in the pipeline: Jenkins owns its workspace.
- Result: workspace scan = **0 findings** (our project has no dependencies). On a real project with 200 dependencies it finds the 3 that are CVE-listed.
- **Trivy DB cache is per-user:** each user (ec2-user, root, jenkins) downloads its own ~2 GB copy. `--skip-version-check` silences the "new version available" notice.

## The REAL secret-leak demo (this actually happened)

Running `trivy fs .` in the **home directory** (not the workspace) scanned `.bash_history` and found our GitHub PAT — from an old `git clone https://ranjay24:TOKEN@github.com/...` — reported as **2 × CRITICAL**. Trivy masks secrets (`***`) in output so the scanner never re-leaks them.

**Lesson:** bash records every command (plaintext, root-readable) → never put tokens in URLs; revoke immediately when exposed. Full incident response is in `02-github.md`.

## The disk-full saga (capacity planning)

Trivy DB extraction needs ~2 GB. An 8 GB disk with Docker+SonarQube+Jenkins had 296 MB free → `no space left on device`.

- Freed 1.1 GB (`docker rmi sonarqube:lts-community`, `yum clean all`) → still not enough.
- Real fix: **grow the EBS volume** 8 → 20 GB (free tier). Steps in `01-aws-ec2.md`.
- Trap: filesystem commands ran from **AWS CloudShell** by mistake (they must run inside the instance via SSH).
- Monitoring lesson: check `df -h` before it bites you. "Alive" ≠ "healthy" — watch metrics and plan capacity.

## Interview one-liner

"I wired Trivy into the pipeline with `--exit-code 1`, so any HIGH/CRITICAL CVE, secret, or misconfiguration fails the build — a security gate, same idea as SonarQube's quality gate."
