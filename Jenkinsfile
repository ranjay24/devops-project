pipeline {
    agent any
    stages {
        stage('Maven Build') {
            agent { docker { image 'maven:3.9-eclipse-temurin-11' } }
            steps {
                sh 'mvn -B clean package'
            }
        }
        stage('Publish to Nexus') {
            agent { docker { image 'maven:3.9-eclipse-temurin-11' } }
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )]) {
                        writeFile file: 'settings.xml', text: """<settings>
  <servers>
    <server>
      <id>devops-releases</id>
      <username>${env.NEXUS_USER}</username>
      <password>${env.NEXUS_PASS}</password>
    </server>
  </servers>
</settings>"""
                        sh 'mvn -B -s settings.xml deploy'
                    }
                }
            }
        }
    }
}
