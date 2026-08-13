"# DevOps Project" 
"I'm setting up a new server."
1. Update it — yum update (fresh, patched base)
2. Install Java — Jenkins is a Java app, needs an engine
3. Add Jenkins's repo — a catalog so yum knows where to find it
4. Import the GPG key — so yum can verify the package is genuinely Jenkins
5. yum install jenkins — install
6. systemctl start + enable — turn on now AND on every boot
7. Grab the unlock password — initialAdminPassword, then set up the web UI