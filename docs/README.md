# DevOps Learning Docs

Organized learning records for the full DevOps pipeline project. Everything that was once crammed into one LEARNING.md is now split into topic files so you can jump straight to what you need.

## The Full Pipeline Flow (the end goal)

```
Jira Task
   → GitHub (source code)
      → Jenkins (CI/CD orchestrator)
         → Maven (build) → SonarQube (code quality) → Aqua Trivy (security scan)
         → Nexus (artifact repo) → Docker image → Aqua Trivy (scan again)
            → Docker push → Kubernetes deploy
   → Monitoring (Prometheus/Grafana etc.)
```

**Project Phases:**
- Phase 1: Networking setup (VPC, instances, K8s) ✅
- Phase 2: GitHub repository ✅
- Phase 3: CI/CD pipeline (in progress)
- Phase 4: Monitoring

---

## Progress Status

| Stage | Status |
|---|---|
| VPC + subnet + SG + IGW + route table | ✅ Done |
| GitHub repo (devops-project) | ✅ Done |
| Jenkins server (EC2 c7i-flex.large + Elastic IP) | ✅ Done |
| Maven installed & builds | ✅ Done |
| First Jenkins build (Jenkinsfile) | ✅ Done |
| Auto trigger (GitHub webhook) | ✅ Done |
| Docker installed on server | ✅ Done |
| SonarQube container (c7i-flex.large, port 9000) | ✅ Done — login works |
| SonarQube in Jenkins pipeline (analysis + quality gate) | ✅ Done — build SUCCESS |
| Trivy (FS scan stage in pipeline) | ✅ Done — build SUCCESS |
| Nexus | ⏳ |
| Docker image + trivy image scan | ⏳ |
| Kubernetes deploy | ⏳ |
| Monitoring | ⏳ |

---

## Resource IDs (my sandbox)

| Resource | ID |
|---|---|
| VPC | `vpc-0a91373581b77a4b8` (10.0.0.0/16) |
| Subnet | `subnet-048f552413422aed8` (10.0.0.0/20, ap-south-2a) |
| Security Group | `sg-02c30f14d59c0fc05` (22, 80, 8080, 9000, 8081) |
| Internet Gateway | `igw-0838db87fc766b89f` |
| Route table | `rtb-0da8fffa4bd38871c` |
| Key pair | `jenkins-key` (file `jenkins-key.pem`) |
| Instance | `i-0e02770e0faa010a0` (c7i-flex.large, 4 GB, ap-south-2a) |
| EBS volume | `vol-0417265ec7dd7fb48` (8 → **20 GB**) |
| Elastic IP | `16.113.34.59` (allocation `eipalloc-0438e03621a8b9dad`) |
| GitHub repo | `ranjay24/devops-project` |

**Service endpoints:**
- Jenkins: `http://16.113.34.59:8080`
- SonarQube: `http://16.113.34.59:9000` (dashboard: `/dashboard?id=DevOps-Project`)
- Nexus: `http://16.113.34.59:8081` (to be set up — SG port 8081 already opened)
- SSH: `ssh -i jenkins-key.pem ec2-user@16.113.34.59`

---

## Current state (where we are)

Pipeline is fully green: **Maven Build → SonarQube Analysis → Quality Gate (OK) → Trivy FS Scan (0 findings)**.

**Next up: Nexus** artifact repository. See `10-commands.md` / `11-resume-prompt.md` for the plan.

---

## Docs index

| File | Covers |
|---|---|
| `01-aws-ec2.md` | VPC, subnet, SG, IGW, route table, EC2 launch, SSH, Elastic IP, instance resize, EBS grow |
| `02-github.md` | Git 3-area flow, repo creation, PAT (token) lessons |
| `03-webhook.md` | Event-driven CI: GitHub → Jenkins auto-trigger |
| `04-maven.md` | Maven install, project structure, `mvn clean package` |
| `05-jenkins.md` | Jenkins install, the Java-21 saga, systemd, credentials |
| `06-pipeline.md` | Pipeline-as-code, Jenkinsfile, all current stages |
| `07-sonarqube.md` | SonarQube setup, the port-9000 saga, pipeline integration bugs |
| `08-trivy.md` | Trivy install, FS scan stage, the REAL secret-leak demo, the disk-full saga |
| `09-gold-points.md` | Every gold point + interview cheat sheet, in one place |
| `10-commands.md` | Quick command references (AWS, server, git, docker) |
| `11-resume-prompt.md` | **THE prompt** — paste this in a new chat to resume learning |

> Tip: `11-resume-prompt.md` is the single most useful file. When starting a fresh chat, paste its contents as the opening message.
