# Setup Guide

This guide will help you set up the development environment and deploy the microservice project.

## Prerequisites

### Development Tools

1. **IDE with Extensions**
   - VS Code with Docker, Kubernetes, and OpenShift extensions
   - Or IntelliJ IDEA with container development plugins

2. **Version Control**
   - Git installed and configured
   - GitHub account with SSH keys configured

3. **Container Runtime**
   - Docker Desktop (recommended) or Podman
   - Docker Compose for local multi-service testing

4. **OpenShift CLI**
   ```bash
   # Download oc CLI matching your cluster version
   curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
   tar -xzf openshift-client-linux.tar.gz
   sudo mv oc /usr/local/bin/
   ```

### OpenShift Environment Options

#### Option A: OpenShift Local (CRC)
```bash
# Download and install CRC
curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/crc/latest/crc-linux-amd64.tar.xz
tar -xf crc-linux-amd64.tar.xz
sudo mv crc-linux-*/crc /usr/local/bin/

# Setup and start
crc setup
crc start

# Get login credentials
crc console --credentials
```

#### Option B: Shared Test Cluster
Contact your mentor team for:
- Cluster API endpoint
- Login credentials
- Project/namespace assignment

## Initial Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd stajdevopsproje
```

### 2. Login to OpenShift
```bash
# For CRC
oc login -u developer -p developer https://api.crc.testing:6443

# For shared cluster
oc login --token=<your-token> --server=<cluster-api>
```

### 3. Create Project/Namespace
```bash
# Create new project
oc new-project <your-name>-demo

# Or switch to assigned project
oc project <assigned-namespace>
```

### 4. Service Account Setup
```bash
# Create service account with edit rights
oc create sa pipeline-sa
oc adm policy add-role-to-user edit -z pipeline-sa
```

### 5. Container Registry Access
```bash
# Create registry secret for image pulls/pushes
oc create secret docker-registry registry-secret \
  --docker-server=ghcr.io \
  --docker-username=<github-username> \
  --docker-password=<github-token>

# Link to service account
oc secrets link pipeline-sa registry-secret
```

## Technology Stack Selection

### Option A: Java with Quarkus
```bash
# Prerequisites
java -version  # Java 11 or later
mvn --version  # Maven 3.6+

# Generate project
mvn io.quarkus.platform:quarkus-maven-plugin:create \
  -DprojectGroupId=com.example \
  -DprojectArtifactId=microservice-demo \
  -Dextensions="resteasy-reactive,smallrye-health,micrometer-registry-prometheus"
```

### Option B: Python with FastAPI
```bash
# Prerequisites
python3 --version  # Python 3.8+
pip3 --version

# Create virtual environment
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn prometheus-client
```

## Local Development

### 1. Install Dependencies
```bash
# Java/Maven
cd app && mvn clean install

# Python
cd app && pip install -r requirements.txt
```

### 2. Run Application Locally
```bash
# Java/Quarkus
./mvnw quarkus:dev

# Python/FastAPI
uvicorn main:app --reload --host 0.0.0.0 --port 8080
```

### 3. Verify Health Endpoints
```bash
curl http://localhost:8080/healthz
curl http://localhost:8080/ready
curl http://localhost:8080/metrics
curl http://localhost:8080/api/v1/hello
```

## Next Steps

1. **Develop Microservice** - Follow [development.md](development.md)
2. **Build Container** - See [../build/README.md](../build/README.md)
3. **Setup CI/CD** - Configure pipelines in [../cicd/README.md](../cicd/README.md)
4. **Deploy to OpenShift** - Use manifests in [../openshift/README.md](../openshift/README.md)

## Troubleshooting

### Common Issues

1. **OC CLI Login Fails**
   - Verify cluster endpoint and credentials
   - Check network connectivity
   - Ensure certificates are valid

2. **Permission Denied**
   - Verify service account has correct roles
   - Check namespace permissions
   - Confirm registry access

3. **Container Build Fails**
   - Check Docker daemon is running
   - Verify base image availability
   - Check dockerfile syntax

For more issues, see [troubleshooting.md](troubleshooting.md). 