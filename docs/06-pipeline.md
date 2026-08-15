# 06 — Pipeline (pipeline-as-code)

Jenkins builds are defined **as code** in a `Jenkinsfile` committed to the repo. No clicking in the UI to configure steps — the pipeline is versioned, reviewable, repeatable.

## Declarative structure

```groovy
pipeline {
    agent any        // run on any available agent (node)
    stages {         // ordered list of phases
        stage('Name') { steps { ... } }
    }
}
```

## The full current Jenkinsfile

```groovy
pipeline {
    agent any
    stages {
        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarQubeScanner'
                    withSonarQubeEnv('SonarQube') {
                        sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=DevOps-Project -Dsonar.sources=. -Dsonar.java.binaries=target/classes -Dsonar.sourceEncoding=UTF-8 -Dsonar.exclusions=target/**"
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Trivy FS Scan') {
            steps {
                sh '/usr/local/bin/trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 .'
            }
        }
    }
}
```

**Current pipeline (all green):**
```
Maven Build → SonarQube Analysis → Quality Gate (OK) → Trivy FS Scan (0 findings)
```

## How each stage works

| Stage | What it does | Why it matters |
|---|---|---|
| `Maven Build` | `mvn clean package` → builds `target/devops-project-1.0.0.jar` | Produces the artifact |
| `SonarQube Analysis` | Runs sonar-scanner (tool `SonarQubeScanner`) against the code with credentials/token | Code quality + bugs + smells |
| `Quality Gate` | `waitForQualityGate abortPipeline: true` — waits for SonarQube's verdict; aborts if "failed" | Enforces quality as a gate |
| `Trivy FS Scan` | Scans source for vulns/secrets/misconfig; `--exit-code 1` fails the build if HIGH/CRITICAL | Enforces security as a gate |

## Why full paths and explicit tools (the "works in my terminal, not in the pipeline" bug)

- `def scannerHome = tool 'SonarQubeScanner'` resolves the scanner's real install path at runtime (this plugin version registers no short name the declarative `tools` block accepts).
- `/usr/local/bin/trivy` full path — the Jenkins service may run with a restricted PATH that doesn't include `/usr/local/bin`. Full path = no surprise.
- No `sudo` needed in the pipeline: Jenkins **owns** its workspace.

## Gate vs report (interview gold)

- SonarQube **analysis** is async: it runs on SonarQube, then **calls back** Jenkins via webhook. The pipeline must `waitForQualityGate` (with a timeout) to read the verdict.
- Trivy is synchronous: `--exit-code 1` means "exit 1 if findings" → `sh` step fails → build aborts. A *report* only informs; a *gate* blocks.

## Job setup (one-time)

1. **Manage Jenkins → Credentials** → add GitHub PAT as `github-credentials` (Username with password).
2. **New Item → Pipeline** → Definition: **Pipeline script from SCM** → Git repo URL + `github-credentials` + branch `*/main` + file `Jenkinsfile`.
3. Trigger: webhook (see `03-webhook.md`) or manual **Build Now**.
4. First run: Console Output → `Finished: SUCCESS`.
