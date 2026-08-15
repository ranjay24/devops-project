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