FROM eclipse-temurin:11-jre
WORKDIR /app
COPY target/devops-project-1.0.0.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]