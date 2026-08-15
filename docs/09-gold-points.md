# 09 — Gold Points & Interview Cheat Sheet

All the "extra credit" learnings in one place. Review before interviews.

## Interview cheat sheet (one-liners)

- "I set up an isolated VPC with a public subnet (IGW route + public IPs), firewalled by security groups."
- "I installed Jenkins as a systemd service on an EC2 instance, added its signed repo, and fixed a Java-21 compatibility issue found via journalctl."
- "Pipelines are code — Jenkinsfile in the repo — and secrets live in Jenkins Credentials, never in code."
- "Maven produces the jar artifact; Jenkins orchestrates; Nexus stores; Docker packages; K8s deploys."
- "SonarQube gives code quality as an async gate (scanner runs analysis, quality-gate plugin reads the webhook verdict)."
- "Trivy gives security as a gate — `--exit-code 1` fails the build on HIGH/CRITICAL findings."

## AWS / networking

- **Public vs private subnet:** public = route to IGW (0.0.0.0/0) AND auto-assign public IP. Not a checkbox.
- **SG = stateful** (responses auto-allowed); **NACL = stateless** (rules both directions).
- Main route table = default for subnets with no explicit association.
- CIDR: /16 = 65,536 IPs, /20 = 4,096 IPs (4,091 usable).
- **Stop vs Terminate:** stop keeps storage (still billed); terminate deletes permanently.
- EBS volumes grow **online** (no stop) via `modify-volume` + `growpart` + `xfs_growfs`.
- AWS CLI default region ≠ your region → **always `--region ap-south-2`**.

## Troubleshooting order (memorize this!)

**Port/timeout chain:** app local (`curl localhost`) → same-host public IP (`curl <public-ip>`) → AWS SG/NACL → your machine (`Test-NetConnection`) → your network. Rule out layers one at a time.

- `ERR_CONNECTION_TIMED_OUT` = packets **dropped** (firewall). `connection refused` = nothing listening. The error type tells you which side to investigate.
- "Works from server, fails from laptop" = problem is between laptop and cloud.
- systemd: `systemctl status` → `journalctl -u <svc>` → root cause → fix → `reset-failed` → start.

## Linux / system

- yum = Red Hat family; apt = Debian/Ubuntu family.
- Repo file + GPG key = signed, verified packages (supply-chain security).
- `systemctl start` (now) vs `enable` (boot); `reset-failed` clears start-limit lock.
- `/opt` = manually installed software; `ln -sf` symlink = pointer/shortcut.
- Multiple JVMs → version conflicts via `alternatives`; check `alternatives --display java`.
- **Reboot test:** always verify a service restarts cleanly after a reboot.
- **Capacity:** "alive" (status checks pass) ≠ "healthy" (performing). Watch metrics, plan RAM/disk.

## Git / security

- Git 3-area flow: working dir → `add` (staging) → `commit` → `push`.
- **Never put credentials in URLs** (`https://user:TOKEN@...`) — they land in bash history.
- `.bash_history` is plaintext, root-readable — attackers harvest it. `history -c && rm -f ~/.bash_history`.
- Tokens: scoped, revocable, stored in Jenkins Credentials, rotate when exposed.

## Containers

- Containers **share the host kernel**; VMs **virtualize hardware**.
- Image = class/template; container = instance/running copy.
- `--restart unless-stopped` = auto-restart on crash AND reboot.
- Containers are **ephemeral** — prod uses named volumes for data.
- `docker logs <name>` = container journal; `-p host:container` = port mapping; `-e` = env config.
- Two Docker engines trap: laptop prompt vs server prompt — know which one you're in.

## CI/CD concepts

- Webhooks = event-driven (push-not-poll), vs Poll SCM = wasteful polling.
- Jenkins = orchestrator; Maven = builder; Nexus = artifact store; Docker = packaging; K8s = deployment.
- Gate vs report: a gate *blocks* the pipeline (quality gate, `--exit-code 1`); a report only informs.
- Full path vs bare name in pipelines = the "works in my terminal, not in the pipeline" bug.
- SonarQube analysis is **async** (webhook callback) → `waitForQualityGate`.
