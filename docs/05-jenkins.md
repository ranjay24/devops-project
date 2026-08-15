# 05 — Jenkins

The CI/CD orchestrator. Installed as a **systemd service** on the EC2 server, reachable at `http://16.113.34.59:8080`.

## Install (memory story: update → engine → catalog → trust → install → run → unlock)

| Step | Command |
|---|---|
| Update | `sudo yum update -y` |
| Java (first try) | `sudo amazon-linux-extras install java-openjdk11 -y` |
| Jenkins repo | `sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo` |
| GPG key | `sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key` |
| Install | `sudo yum install -y jenkins` |
| Start | `sudo systemctl start jenkins` |
| Enable (boot) | `sudo systemctl enable jenkins` |
| Status | `sudo systemctl status jenkins` |
| Unlock pwd | `sudo cat /var/lib/jenkins/secrets/initialAdminPassword` |

Why repo + GPG key? The repo file (`/etc/yum.repos.d/*.repo`) tells yum where to download from; the GPG key **signs** packages so you only install trusted, verified software (supply-chain security).

## THE Java-21 saga (MUST remember)

**Symptom:** Jenkins won't start. Logs (`sudo journalctl -u jenkins -n 30 --no-pager`) showed:
`Java 11 older than minimum (Java 21)`.

**Root cause:** Jenkins 2.568.2 requires **Java 21**, not 11/17.

**Fix — install Corretto 21:**
```
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo yum install -y java-21-amazon-corretto-devel
sudo systemctl reset-failed jenkins
sudo systemctl start jenkins
```

### The second bug — "works until reboot"

Jenkins passed the Java check, then **failed after a reboot** (during the instance resize). `journalctl` showed `Java 17 older than minimum (Java 21)`.

Root cause: yum's Maven pulled in **java-17** as a dependency → the `alternatives` system switched the default Java from 21 → 17. Jenkins only noticed on fresh start.

Diagnosis chain:
```
systemctl status
journalctl -u jenkins
ls /usr/lib/jvm/
alternatives --display java
alternatives --set java /usr/lib/jvm/java-21-amazon-corretto/bin/java
sudo systemctl reset-failed jenkins
sudo systemctl start jenkins
```

**Lesson:** verify a service restarts cleanly after a reboot ("reboot test"). Multiple JVMs on one box = version conflicts via `alternatives`.

## systemd cheat sheet

| Task | Command |
|---|---|
| Start now | `sudo systemctl start jenkins` |
| Start at boot | `sudo systemctl enable jenkins` |
| Status | `sudo systemctl status jenkins` |
| Logs | `sudo journalctl -u jenkins --no-pager` |
| Clear start-limit lock | `sudo systemctl reset-failed jenkins` |

Troubleshooting pattern: `systemctl status` → `journalctl -u <svc>` → find root cause → fix → `reset-failed` → start.

## Credentials (secrets)

Store secrets in **Manage Jenkins → Credentials**, never in code or chat:

| Credential ID | Type | Holds |
|---|---|---|
| `github-credentials` | Username with password | GitHub PAT (used to checkout the repo) |
| `sonar-token` | Secret text | SonarQube token (used by analysis) |

Rotate any credential the moment it might be exposed (see `02-github.md`).

## Container hosting (why Docker is on this box)

Jenkins itself is a service; SonarQube runs as a **Docker container** on the same server (port 9000). Docker engine:
```
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
```
Containers vs VMs (interview): a container **shares the host kernel**; a VM **virtualizes the hardware**. Image = class/template; container = instance/running copy.
