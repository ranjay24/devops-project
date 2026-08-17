# 13 — Dockerize, Registry & Kubernetes Deploy (2026-08-17)

## What we did this session

Dockerized the app, pushed the image to a local registry, and deployed to Kubernetes.

---

## Stage 1: Dockerize the App

### Build the JAR (no local Maven — Docker container)

Maven is not installed on the Windows host. We run it inside a Docker container:

```
docker run --rm -v "${PWD}:/app" -w /app maven:3.9-eclipse-temurin-11 mvn -B clean package
```

**Gotcha:** `%cd%` (CMD variable) doesn't work in PowerShell — use `"${PWD}"` instead.

### Fix: no main manifest attribute

The JAR was missing the main class in its manifest. `java -jar app.jar` couldn't find `main()`.

**Fix:** Added `maven-jar-plugin` to `pom.xml`:

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            <version>3.3.0</version>
            <configuration>
                <archive>
                    <manifest>
                        <mainClass>com.example.HelloWorld</mainClass>
                    </manifest>
                </archive>
            </configuration>
        </plugin>
    </plugins>
</build>
```

### Build the Docker image

```
docker build -t devops-app:1.0.0 .
```

Dockerfile reads: `eclipse-temurin:11-jre` → `WORKDIR /app` → `COPY target/devops-project-1.0.0.jar app.jar` → `ENTRYPOINT ["java", "-jar", "app.jar"]`

### Run the container

```
docker run -d -p 8080:8080 --name devops-container devops-app:1.0.0
docker logs devops-container
```

Output: `Hello DevOps World! v2`

**Note:** This is a console app — it prints and exits. `Exited (0)` = success. Not a web server, so `localhost:8080` won't serve a page in browser.

---

## Stage 2: Local Docker Registry

### What is a registry?

A storage warehouse for Docker images (like GitHub for code). Docker Hub is the public default; we run a local one.

### Start the registry

```
docker run -d -p 5000:5000 --name local-registry registry:2
```

### Tag and push the image

```
docker tag devops-app:1.0.0 localhost:5000/devops-app:1.0.0
docker push localhost:5000/devops-app:1.0.0
```

### Verify

```
curl http://localhost:5000/v2/devops-app/tags/list
```

Output: `{"name":"devops-app","tags":["1.0.0"]}`

---

## Stage 3: Kubernetes Deploy

### Cluster setup

Enabled Kubernetes via Docker Desktop (Kubeadm, single-node cluster).

- `kubectl cluster-info` → control plane at `https://kubernetes.docker.internal:6443`
- `kubectl get nodes` → `docker-desktop` status `Ready`, v1.34.1

### Deployment YAML (`k8s-deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devops-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: devops-app
  template:
    metadata:
      labels:
        app: devops-app
    spec:
      containers:
      - name: devops-app
        image: localhost:5000/devops-app:1.0.0
        imagePullPolicy: Never
```

**Key:** `imagePullPolicy: Never` — tells K8s to use the local registry, not Docker Hub.

### Service YAML (`k8s-service.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: devops-app-service
spec:
  type: NodePort
  selector:
    app: devops-app
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30080
```

### Apply and verify

```
kubectl apply -f k8s-deployment.yaml
kubectl apply -f k8s-service.yaml
kubectl get pods
kubectl get svc devops-app-service
kubectl logs -l app=devops-app --tail=20
```

**Result:** 2 pods running, output `Hello DevOps World! v2`, service on `8080:30080/TCP`.

**Note:** Pods show `Completed` (not `Running`) because the app is a console app that exits after printing. K8s keeps restarting it (RESTARTS counter). This is expected.

---

## Commands learned this session

| Command | What it does |
|---|---|
| `docker run --rm -v "${PWD}:/app" -w /app maven:... mvn ...` | Run Maven in a Docker container (no local install) |
| `docker build -t name:tag .` | Build Docker image from Dockerfile |
| `docker run -d -p host:container --name x image` | Run container in background |
| `docker logs container` | View container output |
| `docker ps -a --filter name=x` | List containers with filter |
| `docker rm -f container` | Force remove container |
| `docker tag source target` | Create an alias tag for an image |
| `docker push registry/image:tag` | Upload image to registry |
| `kubectl apply -f file.yaml` | Apply config to K8s cluster |
| `kubectl get nodes` | List cluster nodes |
| `kubectl get pods` | List pods and status |
| `kubectl get svc` | List services and ports |
| `kubectl logs -l label=value` | View logs by label |
| `kubectl delete -f file.yaml` | Remove resources from cluster |

---

## Lessons learned

1. **PowerShell vs CMD variables** — `%cd%` is CMD, `"${PWD}"` is PowerShell.
2. **JAR manifest** — `java -jar` needs `Main-Class` in MANIFEST.MF. Fix: `maven-jar-plugin` in `pom.xml`.
3. **Console vs web app** — Console apps print and exit; `Exited (0)` is success, not a crash. Browser won't show anything.
4. **Local registry tag format** — Must include registry address: `localhost:5000/devops-app:1.0.0`.
5. **`imagePullPolicy: Never`** — Required when using a local registry (K8s defaults to Docker Hub).
6. **Kubernetes self-healing** — If a Pod exits, Deployment immediately creates a replacement.
7. **Docker Desktop K8s** — Kubeadm option creates a single-node cluster; simpler than `kind` for beginners.

---

## What's next

1. ~~Dockerize the app~~ ✅
2. ~~Push to registry~~ ✅
3. ~~Kubernetes deploy~~ ✅
4. **Monitoring (Prometheus + Grafana)** — next session
5. Re-add SonarQube + Trivy FS stages (later)
