# 01 — AWS & EC2

Everything about the AWS side: networking (VPC) and compute (EC2). Region used throughout: **ap-south-2** (Hyderabad). The AWS CLI default region is `us-east-1` — **always pass `--region ap-south-2`** on every AWS command.

## Concept: VPC

> "A VPC is an isolated virtual network in the cloud. I control the IP ranges (CIDR), subnets, and firewall rules. Nothing enters or leaves unless I allow it."

Networking pieces built:

| Step | Command |
|---|---|
| Create VPC | `aws ec2 create-vpc --cidr-block 10.0.0.0/16` |
| Create subnet | `aws ec2 create-subnet --vpc-id vpc-0a91373581b77a4b8 --cidr-block 10.0.0.0/20 --availability-zone ap-south-2a` |
| Create SG | `aws ec2 create-security-group --vpc-id vpc-0a91373581b77a4b8 --group-name my-sg --description "Allow SSH and HTTP traffic"` |
| SG rule (SSH) | `aws ec2 authorize-security-group-ingress --group-id sg-02c30f14d59c0fc05 --protocol tcp --port 22 --cidr 0.0.0.0/0` |
| SG rule (HTTP) | `aws ec2 authorize-security-group-ingress --group-id sg-02c30f14d59c0fc05 --protocol tcp --port 80 --cidr 0.0.0.0/0` |
| SG rule (Jenkins 8080) | `aws ec2 authorize-security-group-ingress --group-id sg-02c30f14d59c0fc05 --protocol tcp --port 8080 --cidr 0.0.0.0/0` |
| SG rule (SonarQube 9000) | same pattern, `--port 9000` |
| SG rule (Nexus 8081) | same pattern, `--port 8081` |
| Create IGW | `aws ec2 create-internet-gateway` |
| Attach IGW | `aws ec2 attach-internet-gateway --internet-gateway-id igw-0838db87fc766b89f --vpc-id vpc-0a91373581b77a4b8` |
| Create route table | `aws ec2 create-route-table --vpc-id vpc-0a91373581b77a4b8` |
| Internet route | `aws ec2 create-route --route-table-id rtb-0da8fffa4bd38871c --destination-cidr-block 0.0.0.0/0 --gateway-id igw-0838db87fc766b89f` |
| Associate subnet→RT | `aws ec2 associate-route-table --subnet-id subnet-048f552413422aed8 --route-table-id rtb-0da8fffa4bd38871c` |
| Public IP on subnet | `aws ec2 modify-subnet-attribute --subnet-id subnet-048f552413422aed8 --map-public-ip-on-launch` |

**Gold points (networking):**
- A subnet is "public" when BOTH: (1) its route table has `0.0.0.0/0 → IGW`, AND (2) it auto-assigns public IPs. It's not a checkbox.
- **Security groups are STATEFUL** (allowed inbound auto-allows the response out). **NACLs are stateless** (need rules both directions).
- The **main route table** is used by any subnet without an explicit association.
- CIDR math: `/16` = 65,536 IPs; `/20` = 4,096 IPs (4,091 usable).

## Launching the Jenkins EC2 instance

| Concept | Notes |
|---|---|
| AMI | OS template/snapshot. One AMI → many instances. |
| Architecture | x86_64 (t2/t3) vs arm64 (t4g, Graviton). AMI & instance type MUST match. |
| Free tier | Varies by region — always check: `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true` |
| Tags | Key-value metadata; cost allocation + automation. |
| Stop vs Terminate | Stop keeps storage (still billed for disk); Terminate deletes permanently. |

Find the latest x86_64 Amazon Linux 2 AMI:

```
aws ec2 describe-images --owners amazon --filters Name=architecture,Values=x86_64 Name=name,Values="amzn2-ami-hvm-*" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text --region ap-south-2
```

Launch instance:

```
aws ec2 run-instances --image-id ami-07839dbb9305a87c5 --instance-type t3.micro --key-name jenkins-key --subnet-id subnet-048f552413422aed8 --security-group-ids sg-02c30f14d59c0fc05
```

## SSH into the server

```
ssh -i jenkins-key.pem ec2-user@16.113.34.59
```

- `-i <key>` = private-key auth; first connect `yes` = TOFU (trust on first use).
- Amazon Linux default user = `ec2-user`.

## Elastic IP (stable public address)

- A normal public IP is temporary (released on stop). An **Elastic IP** is a reserved, stable public IP.
- `aws ec2 allocate-address` → associate: `aws ec2 associate-address --instance-id i-0e02770e0faa010a0 --allocation-id eipalloc-0438e03621a8b9dad`

## Instance resize (vertical scaling = scale UP)

Needs stop → modify → start:

```
aws ec2 stop-instances --instance-ids i-0e02770e0faa010a0 --region ap-south-2
aws ec2 modify-instance-attribute --instance-id i-0e02770e0faa010a0 --instance-type t3.small --region ap-south-2
aws ec2 start-instances --instance-ids i-0e02770e0faa010a0 --region ap-south-2
```

- History: t3.micro (1 GB) → t3.small (2 GB) → **c7i-flex.large (4 GB)**. SonarQube needs the RAM.
- Scale UP (resize) vs scale OUT (more instances behind a load balancer) — cloud-native prefers scale OUT.

## Growing the EBS disk (online, no stop needed)

We hit **`no space left on device`** — the Trivy vulnerability DB needs ~2 GB to extract, and an 8 GB disk with Docker+SonarQube+Jenkins was full (97%).

Diagnosis chain: `df -h` → `/var` 5.3 G → `/var/lib/docker` 4.1 G (images + container layers).

Fix = grow the volume + filesystem. EBS free tier is **30 GB**, so 20 GB costs **$0**.

1. **Resize the volume (API — runs anywhere):**
   ```
   aws ec2 modify-volume --region ap-south-2 --volume-id vol-0417265ec7dd7fb48 --size 20
   ```
2. **Wait until `optimizing`/`completed`:**
   ```
   aws ec2 describe-volumes-modifications --region ap-south-2 --volume-ids vol-0417265ec7dd7fb48 --query "VolumesModifications[0].ModificationState" --output text
   ```
3. **On the server (filesystem commands MUST run inside the instance):**
   ```
   sudo yum install -y cloud-utils-growpart
   sudo growpart /dev/nvme0n1 1      # extend the partition entry
   sudo xfs_growfs -d /               # extend the XFS filesystem
   df -h                              # 20 GB now
   ```
- `growpart` = extend the *partition*; `xfs_growfs` = extend the *filesystem* (XFS only grows, never shrinks).

**Trap that bit us:** the filesystem commands were run from **AWS CloudShell** (a free AWS browser terminal, NOT our instance). AWS API calls work anywhere, but `growpart`/`xfs_growfs` touch the instance's disks → must run via SSH on the server. **Multiple terminals = always confirm which one you're in** (CloudShell prompt is `~ $`; the server prompt is `[ec2-user@ip-10-0-15-130 ~]$`).
