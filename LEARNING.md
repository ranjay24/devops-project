# DevOps Full-Project Learning Log

> A step-by-step record of everything learned while building the full DevOps pipeline.
> Updated as we progress. Gold points = interview extra credit.

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
| Jenkins server (EC2 t3.small + Elastic IP) | ✅ Done |
| Maven installed & builds | ✅ Done |
| First Jenkins build (Jenkinsfile) | ✅ Done |
| Auto trigger (GitHub webhook) | ✅ Done |
| SonarQube | ⏳ Next |
| Trivy | ⏳ |
| Nexus | ⏳ |
| Docker | ⏳ |
| Kubernetes deploy | ⏳ |
| Monitoring | ⏳ |

---

## Phase 1 — AWS Networking (ap-south-2 / Hyderabad)

### Concept: VPC
> "A VPC is an isolated virtual network in the cloud. I control the IP ranges (CIDR), subnets, and firewall rules. Nothing enters or leaves unless I allow it."

### Commands executed

| Step | Command |
|---|---|
| Create VPC | `aws ec2 create-vpc --cidr-block 10.0.0.0/16` |
| Create subnet | `aws ec2 create-subnet --vpc-id vpc-0a91373581b77a4b8 --cidr-block 10.0.0.0/20 --availability-zone ap-south-2a` |
| Create SG | `aws ec2 create-security-group --vpc-id vpc-0a91373581b77a4b8 --group-name my-sg --description "Allow SSH and HTTP traffic"` |
| SG rule (SSH) | `aws ec2 authorize-security-group-ingress --group-id sg-02c30f14d59c0fc05 --protocol tcp --port 22 --cidr 0.0.0.0/0` |
| SG rule (HTTP) | `aws ec2 authorize-security-group-ingress --group-id sg-02c30f14d59c0fc05 --protocol tcp --port 80 --cidr 0.0.0.0/0` |
| SG rule (Jenkins 8080) | `aws ec2 authorize-security-group-ingress --group-id sg-02c30f14d59c0fc05 --protocol tcp --port 8080 --cidr 0.0.0.0/0` |
| Create IGW | `aws ec2 create-internet-gateway` |
| Attach IGW | `aws ec2 attach-internet-gateway --internet-gateway-id igw-0838db87fc766b89f --vpc-id vpc-0a91373581b77a4b8` |
| Create route table | `aws ec2 create-route-table --vpc-id vpc-0a91373581b77a4b8` |
| Internet route (FIXED!) | `aws ec2 create-route --route-table-id rtb-0da8fffa4bd38871c --destination-cidr-block 0.0.0.0/0 --gateway-id igw-0838db87fc766b89f` |
| Associate subnet→RT | `aws ec2 associate-route-table --subnet-id subnet-048f552413422aed8 --route-table-id rtb-0da8fffa4bd38871c` |
| Public IP on subnet | `aws ec2 modify-subnet-attribute --subnet-id subnet-048f552413422aed8 --map-public-ip-on-launch` |

### Resource IDs (my sandbox)
- VPC: `vpc-0a91373581b77a4b8`
- Subnet: `subnet-048f552413422aed8` (10.0.0.0/20, ap-south-2a)
- Security Group: `sg-02c30f14d59c0fc05` (SSH 22, HTTP 80, 8080)
- Internet Gateway: `igw-0838db87fc766b89f`
- Route table: `rtb-0da8fffa4bd38871c`
- Key pair: `jenkins-key`
- Instance: `i-0e02770e0faa010a0` (t3.small, ap-south-2a)
- Elastic IP: `16.113.34.59` (allocation `eipalloc-0438e03621a8b9dad`)

### Gold points learned
- **Public vs private subnet**: a public subnet = route to IGW (0.0.0.0/0) AND auto-assign public IP. It's NOT a checkbox.
- **SG = stateless?** NO — security groups ARE stateful (allowed inbound auto-allows responses out). NACLs are stateless. (Correct this: SG stateful, NACL stateless!)
- **Main route table** is the default for subnets with no explicit association.
- **CIDR**: /16 = 65,536 IPs, /20 = 4,096 IPs (4091 usable).

---

## Phase 2 — GitHub Repository

### Commands
```
git init
gh repo create devops-project --private --source=. --remote=upstream
echo "# DevOps Project" > README.md
git add README.md
git commit -m "Add README.md project file"
git push -u upstream main
```

### Gold points
- Git 3-area flow: working dir → `git add` (staging) → `git commit` → `git push`.
- `-u upstream` sets tracking so later pushes are just `git push`.
- `origin` vs `upstream` naming convention.

---

## Phase 3 — CI/CD (in progress)

### 3.1 Launch the Jenkins EC2 instance

| Concept | Notes |
|---|---|
| AMI | OS template/snapshot. One AMI → many instances. |
| Architecture | x86_64 (t2/t3) vs arm64 (t4g, Graviton). AMI & instance type MUST match. |
| Free tier | Varies by region — always check: `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true` |
| Tags | Key-value metadata; cost allocation + automation. |
| Stop vs Terminate | Stop keeps storage (still billed for disk); Terminate deletes permanently. |

Find correct AMI:
```
aws ec2 describe-images --owners amazon --filters Name=architecture,Values=x86_64 Name=name,Values="amzn2-ami-hvm-*" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text --region ap-south-2
```

Launch instance (one-liner, no tags):
```
aws ec2 run-instances --image-id ami-07839dbb9305a87c5 --instance-type t3.micro --key-name jenkins-key --subnet-id subnet-048f552413422aed8 --security-group-ids sg-02c30f14d59c0fc05
```

### 3.2 SSH into the server
```
ssh -i jenkins-key.pem ec2-user@18.61.163.99
```
- `-i <key>` = private-key auth; first connect `yes` = TOFU (trust on first use).
- Amazon Linux default user = `ec2-user`.

### 3.3 Install Jenkins (memory story: update → engine → catalog → trust → install → run → unlock)

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

**The Java-version bug we hit:** Jenkins 2.568.2 requires **Java 21** (not 11/17). Logs via
`sudo journalctl -u jenkins -n 30 --no-pager` showed: *"Java 11 older than minimum (Java 21)."*

Fix — install Corretto 21:
```
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo yum install -y java-21-amazon-corretto-devel
sudo systemctl reset-failed jenkins
sudo systemctl start jenkins
```

### 3.4 Install Maven (modern, pinned)
yum Maven is ancient (3.0.5). Pin modern Maven 3.9.9:
```
sudo wget https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz -P /tmp
sudo tar -xzf /tmp/apache-maven-3.9.9-bin.tar.gz -C /opt
sudo ln -sf /opt/apache-maven-3.9.9/bin/mvn /usr/bin/mvn
mvn -version
```

### 3.5 Project code (Maven Java app)
- `pom.xml` — Maven coordinates (`groupId:artifactId:version`), packaging, Java version.
- `src/main/java/com/example/HelloWorld.java` — the tiny app.
- Build: `mvn clean package` → `target/devops-project-1.0.0.jar` (the artifact).

### 3.6 Jenkins pipeline (pipeline-as-code)
- `Jenkinsfile` in the repo = declarative pipeline (`pipeline > agent > stages > steps`).
- Jenkins UI: Manage Jenkins → Credentials → add GitHub PAT (Username with password, ID `github-credentials`).
- New Item → **Pipeline** → Definition: **Pipeline script from SCM** → Git URL + credential + `*/main` + `Jenkinsfile`.
- First build: **Build Now** → Console Output → `Finished: SUCCESS`.

### 3.7 Elastic IP + server resize (maintenance with zero downtime of endpoint)
- A normal public IP is temporary (released on stop). An **Elastic IP** is a reserved, stable public IP.
- Allocate: `aws ec2 allocate-address` → associate: `aws ec2 associate-address --instance-id i-xxx --allocation-id eipalloc-xxx`
- Resize (vertical scaling = scale UP): `stop-instances` → `modify-instance-attribute --instance-type t3.small` → `start-instances`
- We went t3.micro (1GB) → t3.small (2GB) to make room for SonarQube. EIP = endpoint stays stable.
- Scale UP (resize) vs scale OUT (more instances behind a LB) — cloud-native prefers scale OUT.

### 3.8 The "works until reboot" Java bug (MUST-remember)
- Jenkins failed after the resize reboot: `journalctl` showed "Java 17 older than minimum (Java 21)".
- Root cause: yum's Maven pulled in java-17 as a dependency → **alternatives** switched the default from 21 → 17. Jenkins only noticed on fresh start.
- Diagnosis chain: `systemctl status` → `journalctl -u jenkins` → `ls /usr/lib/jvm/` → `alternatives --display java` → `alternatives --set java /usr/lib/jvm/java-21-amazon-corretto/bin/java` → `reset-failed` → `start`.
- Lesson: verify a service restarts cleanly after a reboot ("reboot test").

### 3.9 Automatic trigger (GitHub webhook — event-driven CI)
- Job → Configure → Triggers → **"GitHub hook trigger for GITScm polling"**.
- GitHub → repo → Settings → Webhooks → Add webhook → Payload URL `http://<jenkins-ip>:8080/github-webhook/`, content-type json, push event.
- Result: every `git push` → GitHub POSTs to Jenkins → build runs automatically (no human, no polling).
- Webhooks = event-driven (push-not-poll) — the modern pattern (vs Poll SCM = wasteful polling).
- Requires Jenkins to be publicly reachable — that's what the Elastic IP provides.

### Gold points learned
- yum = Red Hat family; apt = Debian/Ubuntu family.
- Repos (`/etc/yum.repos.d/*.repo`) + GPG key = signed, verified packages (supply-chain security).
- `systemctl start` (now) vs `enable` (every boot); `reset-failed` clears start-limit lock.
- systemd troubleshooting: `systemctl status` → `journalctl -u <svc> --no-pager` → root cause → fix.
- `/opt` = manually installed software; symlink `ln -sf` = pointer/shortcut.
- **Secrets**: never paste tokens in code/chat — store in Jenkins Credentials, rotate when exposed.
- Jenkins = orchestrator; Maven = builder (separation of tools).
- Multiple JVMs on one box = version conflicts via **alternatives**; check with `alternatives --display`.
- Containers (Docker) vs VMs: container shares host kernel, VM virtualizes hardware.

---

## Useful One-Liner References

| Task | Command |
|---|---|
| List instances | `aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]" --output text` |
| Tag instance | `aws ec2 create-tags --resources i-xxx --tags Key=Name,Value=jenkins-master` |
| Terminate | `aws ec2 terminate-instances --instance-ids i-xxx` |
| Clear terminal | `clear` (bash) / `cls` (cmd) |

---

## Next Steps
- [ ] Automate build trigger (GitHub webhook / Poll SCM)
- [ ] SonarQube setup (code quality)
- [ ] Aqua Trivy security scan (dependencies + container image)
- [ ] Nexus artifact repository
- [ ] Docker image build + push
- [ ] Kubernetes cluster + deploy
- [ ] Monitoring (Prometheus/Grafana)

## Interview Cheat Sheet (one-liners)
- "I set up an isolated VPC with a public subnet (IGW route + public IPs), firewalled by security groups."
- "I installed Jenkins as a systemd service on an EC2 instance, added its signed repo, and fixed a Java-21 compatibility issue found via journalctl."
- "Pipelines are code — Jenkinsfile in the repo — and secrets live in Jenkins Credentials, never in code."
- "Maven produces the jar artifact; Jenkins orchestrates; Nexus stores; Docker packages; K8s deploys."
