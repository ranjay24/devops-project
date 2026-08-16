# DevOps Project — Learning Hub

Everything we've learned while building the full DevOps pipeline is organized in the **`docs/`** folder, one file per topic.

## Start here

- **Read the index & progress:** `docs/README.md`
- **Paste to resume in a new chat:** `docs/11-resume-prompt.md`

## Docs index

| File | Covers |
|---|---|
| `docs/README.md` | Pipeline flow, progress table, resource IDs, endpoints |
| `docs/01-aws-ec2.md` | VPC, subnet, SG, IGW, route table, EC2, Elastic IP, resize, disk grow |
| `docs/02-github.md` | Git 3-area flow, repo creation, PAT (token) lessons |
| `docs/03-webhook.md` | Event-driven CI: GitHub → Jenkins auto-trigger |
| `docs/04-maven.md` | Maven install, project structure, build |
| `docs/05-jenkins.md` | Jenkins install, Java-21 saga, systemd, credentials |
| `docs/06-pipeline.md` | Pipeline-as-code, full current Jenkinsfile |
| `docs/07-sonarqube.md` | SonarQube setup, port-9000 saga, integration bugs |
| `docs/08-trivy.md` | Trivy scan stage, secret-leak demo, disk-full saga |
| `docs/09-gold-points.md` | All gold points + interview cheat sheet |
| `docs/10-commands.md` | Quick command references |
| `docs/11-resume-prompt.md` | **THE prompt** for a new chat |
| `docs/12-local-pipeline.md` | Fully local rebuild (AWS retired), containers, Jenkins job, lessons, next steps |

## Current state

Pipeline is green **locally**: **Maven Build (Docker agent) → Publish to Nexus**. AWS sandbox retired (terminated, no billing).
Next: **Dockerize the app** — `Dockerfile` written, image build pending (see `docs/README.md`).
