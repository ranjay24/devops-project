# 12 — Fully Local Pipeline (AWS retired)

We moved the whole project OFF AWS (no more instance billing) and rebuilt the pipeline **entirely on the laptop with Docker**. Every tool now runs as a local container.

## Why

The AWS instance (c7i-flex.large) was costing money. Everything left in the roadmap (Nexus, SonarQube, Trivy, Docker image, K8s, Monitoring) runs equally well locally with Docker. The AWS sandbox was **terminated completely** (instance, EIP, SG, IGW, route table, subnet, VPC, key pair) — only AWS default resources remain, nothing project-scoped is billed.

## What's running on the laptop

| Container | Image | Host port | What it is |
|---|---|---|---|
| `nexus` | `sonatype/nexus3` | 8081 | Artifact repository |
| `jenkins` | `jenkins-local` (custom) | 8082 | CI/CD server (with Docker CLI for Docker agents) |
| `ticketdesk-api` / `ticketdesk-db` | — | 8080 / 3307 | UNRELATED project — never touch |

Jenkins image (`docker/jenkins/Dockerfile`) = `jenkins/jenkins:lts-jdk17` + `docker.io` CLI, run as root so it can use the mounted Docker socket.

## Endpoints & credentials

- Jenkins: `http://localhost:8082`
- Nexus: `http://localhost:8081`
- Jenkins credentials in vault: `github-credentials` (GitHub PAT), `nexus-credentials` (Nexus admin)

## Jenkins pipeline job

- Name: `devops-project-pipeline`
- Pipeline from SCM → `https://github.com/ranjay24/devops-project.git` (private → needs `github-credentials`)
- **Lightweight checkout disabled** (avoids git-plugin flakiness)
- Jenkinsfile v2: `agent any` (controller does the checkout) → stage-level **Docker agents** `maven:3.9-eclipse-temurin-11` for Maven Build + Publish to Nexus

## Pipeline status

**GREEN**: `Maven Build → Publish to Nexus` — the JAR `devops-project-1.0.0.jar` is in the `devops-releases` repo and fetchable via
`http://localhost:8081/repository/devops-releases/com/example/devops-project/1.0.0/devops-project-1.0.0.jar` (HTTP 200).

## Lessons learned this session (all real bugs we hit)

1. **Java memory caps** — Nexus default heap (~2.7 GB) crashed a 4 GB box. Fix: `-e INSTALL4J_ADD_VM_PARAMS="-Xms512m -Xmx1024m -XX:MaxDirectMemorySize=1024m"`.
2. **Port collisions** — 8080 already used by ticketdesk-api → Jenkins on `-p 8082:8080`. Never kill the other app; move yours.
3. **Docker socket ≠ Docker CLI** — mounting `/var/run/docker.sock` lets a container talk to the daemon, but the Jenkins container also needs the `docker` CLI binary installed (that's what the `jenkins-local` image adds).
4. **Git "dubious ownership"** — git refuses repos owned by another user (CVE-2022-24765). Container switched from `jenkins` to root user → fixed with `git config --global --add safe.directory '*'` + wiping stale workspaces.
5. **GitHub PAT** — the repo is **private**; GitHub rejects username/password entirely. Jenkins needs a PAT stored as a credential.
6. **The heredoc trap** — indented `EOF` terminator made bash swallow the `mvn deploy` line INTO the settings.xml. Stage "succeeded" but did nothing. Fix: Jenkins `writeFile` step instead of shell heredoc. **Always verify the actual command (`+ mvn`) ran.**
7. **`host.docker.internal`** — a container's `localhost` is itself. To reach the laptop's Nexus from a build container, use `host.docker.internal:8081`.
8. **Docker agents** — build tools live in throwaway `maven:` containers, not baked into Jenkins. `agent { docker { image '...' } }`.

## Next steps

1. **Dockerize the app** — `Dockerfile` written at repo root (needs `mvn package` → `docker build -t devops-app:1.0.0 .` → `docker run`).
2. Trivy image scan of the built image.
3. Push image to a registry (local `registry:2` container or Docker Hub).
4. Kubernetes deploy (Docker Desktop built-in K8s or Minikube).
5. Re-add SonarQube + Trivy FS stages to the pipeline (locally).
6. Monitoring: Prometheus + Grafana.
