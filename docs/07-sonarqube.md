# 07 — SonarQube

Code quality platform. Runs as a Docker container on the Jenkins server, port **9000**. Dashboard: `http://16.113.34.59:9000/dashboard?id=DevOps-Project`.

## Container setup

**Kernel setting Elasticsearch needs** (SonarQube embeds Elasticsearch):
```
sudo sysctl -w vm.max_map_count=262144      # temporary
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf   # permanent (survives reboot)
sudo sysctl -p                              # reload config
```
Interview point: ES maps many virtual-memory regions; below 262144 it refuses to start — a classic "why is my ES container failing?" gotcha.

**Run SonarQube** (current image 26.8, `sonarqube:community`):
```
sudo docker run -d --name sonarqube --restart unless-stopped -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -e SONAR_SEARCH_JAVAOPTS="-Xms512m -Xmx512m" \
  -e SONAR_WEB_JAVAOPTS="-Xms256m -Xmx256m" \
  -e SONAR_CE_JAVAOPTS="-Xms256m -Xmx256m" \
  sonarqube:community
```
- `--restart unless-stopped` = auto-restart on crash AND host reboot (default is `no`).
- Wait for `sudo docker logs --tail 5 sonarqube` to show **`SonarQube is operational`**.
- First login: `admin`/`admin` → forced password change.

Useful docker commands: `docker ps` (running), `docker ps -a` (all), `docker logs <name>`, `docker start <name>`, `docker rm -f <name>`, `docker system prune -f`.

## THE port-9000 troubleshooting saga (interview gold — memorize the order)

**Symptom:** browser → `ERR_CONNECTION_TIMED_OUT` on port 9000, but Jenkins (8080) and SSH (22) worked.

**Diagnostic chain — rule out layers one at a time:**
1. **App up locally?** On server: `curl -I http://localhost:9000` → `200` = app listening fine.
2. **Server-side network OK?** On server: `curl -I http://16.113.34.59:9000` → `200` = AWS path (SG/NACL/routing) fine. (If THIS times out → it's AWS-side.)
3. **SG rule present?** `aws ec2 authorize-security-group-ingress ... --port 9000` returned `InvalidPermission.Duplicate` → rule already existed, SG never the problem. (AWS saying "Duplicate" = config was already there.)
4. **Reachable from my machine?** Windows: `Test-NetConnection 16.113.34.59 -Port 9000` → `TcpTestSucceeded: False`, source IP `10.4.247.130` (private/NAT).
5. **Compare with ports that DO work:** 22 and 8080 OK → the block is specific to port 9000.
6. **Root cause:** the local network (college/office router) **blocks outbound traffic on non-standard ports** like 9000. Not a server issue at all.
7. **Proof/workaround:** mobile hotspot → page loaded instantly.

**Gold points from the saga:**
- `ERR_CONNECTION_TIMED_OUT` = packets **dropped** (firewall silently discards SYN). `connection refused` = something IS answering but nothing is listening. The error type tells you which side to investigate.
- "Works from the server, fails from my laptop" = the problem is *between* laptop and cloud (local network/ISP/local firewall).
- **Two Docker engines:** Git Bash `~ $` on Windows = LAPTOP's Docker; `[ec2-user@... ~]$` = the server. Check the prompt first.
- **Containers are ephemeral:** prod uses named volumes (`-v sonarqube_data:/opt/sonarqube/data`) so data outlives the container.
- Security groups are **stateful** (responses auto-allowed); NACLs are **stateless**.

## Wiring into Jenkins (analysis + quality gate)

**Jenkins side:**
1. Install plugins: **SonarQube Scanner** (runs the scan) + **Sonar Quality Gates** (reads the verdict).
2. Credentials → Global → **Secret text** with the SonarQube token, ID `sonar-token`.
3. Manage Jenkins → System → **SonarQube servers**: Name `SonarQube`, URL `http://16.113.34.59:9000`, token `sonar-token`, tick **Environment variables**.
4. Manage Jenkins → Tools → **SonarQube Scanner**: Name `SonarQubeScanner`, tick **Install automatically**.

**SonarQube side:**
- Project key **`DevOps-Project`** (created in UI).
- Token: My Account → Security → Generate (stored ONLY in Jenkins credentials).
- **Webhook** (critical!): Administration → Configuration → Webhooks → Name `Jenkins`, URL `http://16.113.34.59:8080/sonarqube-webhook/`.

## Bugs we hit & fixed (memorize)

1. `Invalid tool type "sonarScanner"/"sonarRunner"` → this plugin version's tool has NO short name the declarative `tools` block accepts. **Fix:** resolve at runtime: `def scannerHome = tool 'SonarQubeScanner'` then `${scannerHome}/bin/sonar-scanner`.
2. `Could not create Project with key "devops-project". A similar key already exists: "DevOps-Project"` → SonarQube keys are **case-insensitive & unique**. **Fix:** use the EXACT key: `-Dsonar.projectKey=DevOps-Project`.
3. **Quality Gate timed out** (task stuck `IN_PROGRESS`) → `waitForQualityGate` needs SonarQube to **call back** Jenkins. **Fix:** create the **webhook** to `/sonarqube-webhook/`. Without it Jenkins polls until timeout.

## Gold points (SonarQube)

- **Token vs password:** scoped, revocable, never leaves the credentials store. `Secret text` = just a secret value (no username).
- **Two plugins, two jobs:** Scanner *runs* the analysis; Quality Gates *reads* the async verdict (webhook).
- SonarScanner props: `projectKey` must match; `java.binaries` = compiled classes (Java analysis needs bytecode); `exclusions=target/**` = never analyze build output.
