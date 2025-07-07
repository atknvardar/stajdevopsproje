# CI/CD Pipeline Configuration

This directory contains pipeline definitions for continuous integration and deployment.

## Pipeline Engine

**Primary**: OpenShift Pipelines (Tekton)
**Fallback**: Jenkins (if Pipelines Operator unavailable)

## Pipeline Stages

| Stage | Task | Input | Output |
|-------|------|-------|--------|
| `git-clone` | Checkout source code | GitHub webhook | Source code |
| `unit-test` | Run tests + SonarQube | Source | Test reports |
| `build-image` | Build & push OCI image | Source + tests | Registry URL |
| `deploy-dev` | Apply dev manifests | Image | Running pod |
| `e2e-test` | Smoke tests via curl | Dev deployment | Test results |
| `deploy-prod` | Manual promotion | Approval | Prod rollout |

## Directory Structure

```
cicd/
├── pipelines/          # Tekton pipeline definitions
│   ├── pipeline.yaml   # Main pipeline
│   ├── tasks/          # Reusable task definitions
│   └── triggers/       # GitHub webhook triggers
├── jenkins/            # Jenkins pipeline (fallback)
│   └── Jenkinsfile     # Declarative pipeline
└── scripts/            # Pipeline utility scripts
```

## Parameters

- `IMAGE_TAG`: Git commit short hash (`git rev-parse --short HEAD`)
- `NAMESPACE`: Target deployment namespace
- `GITHUB_REPO`: Source repository URL
- `REGISTRY_URL`: Container registry endpoint

## Triggers

- **Push to main**: Full pipeline execution
- **Pull request**: Build + test only (no deployment)
- **Manual**: Production deployment with approval

## Secret Management

Required secrets:
- `github-secret`: GitHub webhook authentication
- `registry-secret`: Container registry credentials
- `sonarqube-token`: Code quality analysis

## Notifications

Pipeline status notifications sent to:
- Slack channel
- Email (on failure)
- GitHub commit status 