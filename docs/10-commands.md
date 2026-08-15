# 10 — Quick Command References

Fast lookup of the commands we use constantly. Details and gold points live in the other docs files.

## AWS (always add `--region ap-south-2`)

| Task | Command |
|---|---|
| List instances | `aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]" --output text --region ap-south-2` |
| Tag instance | `aws ec2 create-tags --resources i-0e02770e0faa010a0 --tags Key=Name,Value=jenkins-master` |
| Open a SG port | `aws ec2 authorize-security-group-ingress --group-id sg-02c30f14d59c0fc05 --protocol tcp --port <PORT> --cidr 0.0.0.0/0` |
| Grow EBS volume | `aws ec2 modify-volume --volume-id vol-0417265ec7dd7fb48 --size 20` |
| EBS grow status | `aws ec2 describe-volumes-modifications --volume-ids vol-0417265ec7dd7fb48 --query "VolumesModifications[0].ModificationState" --output text` |
| Check cost | `aws ce get-cost-and-usage --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) --granularity MONTHLY --metrics UnblendedCost` |
| Free-tier types | `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true` |

## Server (SSH + Linux)

| Task | Command |
|---|---|
| SSH in | `ssh -i jenkins-key.pem ec2-user@16.113.34.59` |
| Disk space | `df -h` |
| Big folders | `sudo du -h --max-depth=1 / 2>/dev/null | sort -h | tail -15` |
| Grow filesystem | `sudo growpart /dev/nvme0n1 1 && sudo xfs_growfs -d /` |
| Clear bash history | `history -c && rm -f ~/.bash_history` |

## Docker (on the server — check the prompt!)

| Task | Command |
|---|---|
| Running containers | `sudo docker ps` |
| All containers | `sudo docker ps -a` |
| Images | `sudo docker images` |
| Logs | `sudo docker logs --tail 5 <name>` |
| Start existing | `sudo docker start <name>` |
| Force remove | `sudo docker rm -f <name>` |
| Clean dangling | `sudo docker system prune -f` |
| Remove image | `sudo docker rmi <image>:<tag>` |

**Our running containers:**
- SonarQube: `sonarqube` on `-p 9000:9000` (`sonarqube:community`)
- (Nexus: `nexus` on `-p 8081:8081` — next)

## Git

| Task | Command |
|---|---|
| Status | `git status` |
| Stage + commit + push | `git add . && git commit -m "msg" && git push` |
| Pull | `git pull` |
| Clone (safe, no token in URL) | `git clone https://github.com/ranjay24/devops-project.git` |

## Trivy

| Scan | Command |
|---|---|
| Filesystem (as in pipeline) | `trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 .` |
| Filesystem (server, needs sudo + full path) | `sudo /usr/local/bin/trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --ignore-unfixed /var/lib/jenkins/workspace/devops-project-pipeline` |
| Image (later) | `trivy image --severity HIGH,CRITICAL --ignore-unfixed <image>` |

## Maven

| Task | Command |
|---|---|
| Build | `mvn clean package` |
| Version | `mvn -version` |

## Endpoints

| Service | URL |
|---|---|
| Jenkins | `http://16.113.34.59:8080` |
| SonarQube dashboard | `http://16.113.34.59:9000/dashboard?id=DevOps-Project` |
| Nexus (next) | `http://16.113.34.59:8081` |
