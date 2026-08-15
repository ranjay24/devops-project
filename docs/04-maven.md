# 04 — Maven

Build tool. Turns source code into a deployable **artifact** (the `.jar`).

## Install (modern, pinned to 3.9.9)

The yum Maven is ancient (3.0.5). We pin a modern release:

```
sudo wget https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz -P /tmp
sudo tar -xzf /tmp/apache-maven-3.9.9-bin.tar.gz -C /opt
sudo ln -sf /opt/apache-maven-3.9.9/bin/mvn /usr/bin/mvn
mvn -version
```

- `/opt` = manually installed software.
- `ln -sf` = symlink (a pointer/shortcut) so `mvn` on the PATH finds it.

## Project structure

```
devops-project/
├── pom.xml                      # Maven coordinates + config
├── Jenkinsfile                  # CI pipeline definition
├── src/main/java/com/example/HelloWorld.java   # the tiny app
└── src/test/...                 # (empty for now)
```

**`pom.xml` essentials** — Maven coordinates (`groupId:artifactId:version` uniquely identify an artifact), packaging type (`jar`), and the Java version.

## Building

```
mvn clean package
```

- `clean` = wipe previous output (the workspace is fresh every Jenkins build anyway).
- `package` = compile + run tests + build the jar.
- Output: `target/devops-project-1.0.0.jar` — **the artifact**.
- Lifecycle (for interviews): compile → test → package → install → deploy.

## Gold points

- Jenkins = **orchestrator** (who runs what); Maven = **builder** (produces the jar). Separation of tools.
- The `.jar` disappears when the workspace is cleaned — that's WHY we need **Nexus** (a place to publish/store the artifact).
- Maven pulls dependencies from repositories; it's a build tool, not a runtime.
