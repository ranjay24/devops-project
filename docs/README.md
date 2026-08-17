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
- Phase 1: Networking setup (VPC, instances) ✅ (AWS retired)
- Phase 2: GitHub repository ✅
- Phase 3: CI/CD pipeline (Jenkins, Maven, Nexus) ✅
- Phase 4: Dockerize + Registry + Kubernetes ✅
- Phase 5: Monitoring (Prometheus + Grafana) ⏳

---

## Progress Status

| Stage | Status |
|---|---|
| VPC + subnet + SG + IGW + route table | ✅ Done (AWS sandbox retired — terminated, no billing) |
| GitHub repo (devops-project) | ✅ Done |
| Jenkins server (EC2 c7i-flex.large + Elastic IP) | ✅ Done (retired) → rebuilt **locally** |
| Maven installed & builds | ✅ Done |
| First Jenkins build (Jenkinsfile) | ✅ Done |
| Auto trigger (GitHub webhook) | ✅ Done (server-era) — locally use SCM polling/build now |
| Docker installed on server | ✅ Done |
| SonarQube container (port 9000) | ✅ Done (server-era) — not yet rebuilt locally |
| SonarQube in Jenkins pipeline (analysis + quality gate) | ✅ Done (server-era) — not yet rebuilt locally |
| Trivy (FS scan stage in pipeline) | ✅ Done (server-era) — not yet rebuilt locally |
| Nexus | ✅ Done — **local**, JAR published & fetchable (HTTP 200) |
| Docker image build + run | ✅ Done — `devops-app:1.0.0`, output `Hello DevOps World! v2` |
| Local Docker registry (port 5000) | ✅ Done — image pushed & verified |
| Kubernetes deploy (Docker Desktop) | ✅ Done — Deployment + Service, 2 replicas running |
| Monitoring | ⏳ Next — Prometheus + Grafana |

---

## Resource IDs (my sandbox)

> ⚠️ **Retired 2026-08-16.** The AWS sandbox was fully terminated (instance, EIP, SG, IGW, route table, subnet, VPC, key pair). Kept below for history only — nothing project-scoped remains on AWS.

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

**Local endpoints (current):**
- Jenkins: `http://localhost:8082`
- Nexus: `http://localhost:8081` (repo `devops-releases`)
- Local Registry: `http://localhost:5000`
- Kubernetes: `https://kubernetes.docker.internal:6443`
- K8s App Service: `localhost:30080` (NodePort)

---

## Current state (where we are)

Pipeline is green **locally**: **Maven Build (Docker agent) → Publish to Nexus** — the JAR is in `devops-releases` (HTTP 200).

Dockerized the app: **`devops-app:1.0.0`** built, pushed to local registry (`localhost:5000`), deployed to Kubernetes with 2 replicas. Console app outputs `Hello DevOps World! v2`.

**Next up: Monitoring** — Prometheus + Grafana for cluster and app metrics. See `12-local-pipeline.md` for the full local setup and `13-docker-registry-k8s.md` for today's Docker/registry/K8s session.

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
| `12-local-pipeline.md` | **Fully local rebuild** (AWS retired), containers, Jenkins job, lessons learned, next steps |
| `13-docker-registry-k8s.md` | Dockerize app, local registry, Kubernetes deploy, lessons learned |

> Tip: `11-resume-prompt.md` is the single most useful file. When starting a fresh chat, paste its contents as the opening message.
