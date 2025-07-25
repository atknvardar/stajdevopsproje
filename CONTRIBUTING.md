# 🤝 Contributing to Enterprise DevOps Pipeline

Thank you for your interest in contributing to our comprehensive DevOps pipeline implementation! This document provides guidelines and information for contributors.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contribution Workflow](#contribution-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Submitting Changes](#submitting-changes)
- [Review Process](#review-process)

## 🤖 Code of Conduct

### Our Pledge

We are committed to making participation in this project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment include:

- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by contacting the project team. All complaints will be reviewed and investigated promptly and fairly.

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Git** for version control
- **Docker** for containerization
- **Kubernetes/OpenShift** cluster access
- **Python 3.11+** for development
- **kubectl/oc CLI** configured
- **Text editor** or IDE of choice

### Repository Structure

```
stajdevopsproje/
├── app/                    # Microservice source code
├── build/                  # Build and containerization
├── cicd/                   # CI/CD pipeline definitions
├── openshift/              # Kubernetes manifests
├── observability/          # Monitoring and logging
├── governance/             # Security and governance
├── testing/                # Testing framework
├── docs/                   # Documentation
├── Makefile               # Build automation
├── README.md              # Project overview
└── CONTRIBUTING.md        # This file
```

## 🔧 Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/stajdevopsproje.git
cd stajdevopsproje

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/stajdevopsproje.git
```

### 2. Set Up Development Environment

```bash
# Set up local development environment
make setup

# Verify setup
make check-deps

# Run tests to ensure everything works
make test
```

### 3. Start Development

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Start local development server
make dev

# Or use Docker Compose for full stack
make dev-docker
```

## 🔄 Contribution Workflow

### 1. Choose Your Contribution Type

#### 🐛 Bug Fixes
- Check existing issues first
- Create issue if not exists
- Include reproduction steps
- Reference issue in PR

#### ✨ New Features
- Discuss in issue first
- Follow architecture patterns
- Include comprehensive tests
- Update documentation

#### 📚 Documentation
- Improve clarity and completeness
- Add examples and code snippets
- Verify all links work
- Follow documentation standards

#### 🧪 Testing
- Add missing test coverage
- Improve test quality
- Add new testing scenarios
- Update testing documentation

#### 🛡️ Security
- Report security issues privately first
- Follow responsible disclosure
- Include reproduction details
- Suggest mitigation strategies

### 2. Development Process

```bash
# Keep your fork updated
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/descriptive-name

# Make your changes
# ... edit files ...

# Test your changes
make test-all

# Format and lint code
make format
make lint

# Commit changes
git add .
git commit -m "feat: add descriptive commit message"

# Push to your fork
git push origin feature/descriptive-name

# Create Pull Request on GitHub
```

## 📝 Coding Standards

### Python Code Standards

#### Style Guide
- Follow **PEP 8** Python style guide
- Use **Black** for code formatting
- Use **isort** for import sorting
- Use **flake8** for linting
- Use **mypy** for type checking

#### Code Quality
```python
# Use type hints
def process_data(input_data: List[Dict[str, Any]]) -> Dict[str, int]:
    """Process input data and return summary statistics."""
    pass

# Use descriptive variable names
user_count = len(active_users)  # Good
n = len(users)                  # Bad

# Add docstrings for functions and classes
class DataProcessor:
    """Processes user data for analytics purposes."""
    
    def calculate_metrics(self, data: List[Dict]) -> Dict[str, float]:
        """Calculate key metrics from user data.
        
        Args:
            data: List of user data dictionaries
            
        Returns:
            Dictionary containing calculated metrics
        """
        pass
```

#### Error Handling
```python
# Use specific exception types
try:
    result = risky_operation()
except ConnectionError as e:
    logger.error(f"Connection failed: {e}")
    raise
except ValidationError as e:
    logger.warning(f"Invalid data: {e}")
    return default_result
```

### YAML/Kubernetes Standards

#### Formatting
```yaml
# Use consistent indentation (2 spaces)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: microservice-demo
  labels:
    app: microservice-demo
    version: v1.0.0
spec:
  replicas: 3
  selector:
    matchLabels:
      app: microservice-demo
```

#### Resource Naming
- Use lowercase with hyphens
- Be descriptive and consistent
- Include environment/purpose in names

#### Labels and Annotations
```yaml
metadata:
  labels:
    app.kubernetes.io/name: microservice-demo
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: api
    app.kubernetes.io/part-of: devops-pipeline
    app.kubernetes.io/managed-by: kustomize
    environment: production
  annotations:
    deployment.kubernetes.io/revision: "1"
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

### Shell Script Standards

```bash
#!/bin/bash
set -euo pipefail

# Use meaningful variable names
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Add help function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Description of what this script does.

Options:
    -h, --help     Show this help message
    -v, --verbose  Enable verbose output
    --dry-run      Show what would be done without executing

Examples:
    $0 --verbose
    $0 --dry-run

EOF
}

# Use functions for reusability
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}
```

## 🧪 Testing Guidelines

### Test Coverage Requirements

- **Minimum Coverage**: 80% for new code
- **Critical Paths**: 100% coverage required
- **Integration Tests**: All API endpoints
- **End-to-End Tests**: Core user workflows

### Testing Levels

#### 1. Unit Tests
```python
import pytest
from unittest.mock import patch, MagicMock
from app.main import app
from fastapi.testclient import TestClient

class TestHealthEndpoints:
    def setup_method(self):
        self.client = TestClient(app)
    
    def test_health_check_returns_healthy_status(self):
        """Test that health check endpoint returns healthy status."""
        response = self.client.get("/healthz")
        
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"
        assert "timestamp" in response.json()
    
    @patch('app.main.check_dependencies')
    def test_readiness_check_with_healthy_dependencies(self, mock_check):
        """Test readiness check when all dependencies are healthy."""
        mock_check.return_value = True
        
        response = self.client.get("/ready")
        
        assert response.status_code == 200
        assert response.json()["status"] == "ready"
```

#### 2. Integration Tests
```python
import pytest
import requests
from testcontainers import DockerContainer

class TestAPIIntegration:
    @pytest.fixture(scope="class")
    def api_container(self):
        """Start API container for integration testing."""
        container = DockerContainer("microservice-demo:latest")
        container.with_exposed_ports(8080)
        
        with container:
            # Wait for container to be ready
            container.get_wrapped_container().reload()
            yield container
    
    def test_api_endpoint_integration(self, api_container):
        """Test API endpoint integration."""
        port = api_container.get_exposed_port(8080)
        base_url = f"http://localhost:{port}"
        
        response = requests.get(f"{base_url}/api/v1/hello")
        
        assert response.status_code == 200
        assert "message" in response.json()
```

#### 3. End-to-End Tests
```bash
#!/bin/bash
# E2E test script

set -euo pipefail

readonly BASE_URL="${BASE_URL:-http://localhost:8080}"
readonly TIMEOUT="${TIMEOUT:-30}"

test_health_endpoints() {
    echo "Testing health endpoints..."
    
    curl -f -m "$TIMEOUT" "$BASE_URL/healthz" || {
        echo "Health check failed"
        return 1
    }
    
    curl -f -m "$TIMEOUT" "$BASE_URL/ready" || {
        echo "Readiness check failed"
        return 1
    }
}

test_api_functionality() {
    echo "Testing API functionality..."
    
    local response
    response=$(curl -s -m "$TIMEOUT" "$BASE_URL/api/v1/hello")
    
    echo "$response" | jq -e '.message' > /dev/null || {
        echo "API response invalid: $response"
        return 1
    }
}

main() {
    test_health_endpoints
    test_api_functionality
    echo "All E2E tests passed!"
}

main "$@"
```

### Performance Testing

```python
import pytest
import time
from concurrent.futures import ThreadPoolExecutor
from fastapi.testclient import TestClient

def test_response_time_under_load():
    """Test that response time remains acceptable under load."""
    client = TestClient(app)
    
    def make_request():
        start_time = time.time()
        response = client.get("/api/v1/hello")
        response_time = time.time() - start_time
        return response.status_code == 200, response_time
    
    # Simulate 50 concurrent requests
    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = [executor.submit(make_request) for _ in range(100)]
        results = [future.result() for future in futures]
    
    success_count = sum(1 for success, _ in results if success)
    response_times = [time for _, time in results]
    
    # Assertions
    assert success_count >= 95  # 95% success rate
    assert max(response_times) < 1.0  # Max 1 second response time
    assert sum(response_times) / len(response_times) < 0.2  # Avg < 200ms
```

## 📚 Documentation Standards

### Documentation Requirements

#### Code Documentation
- **All public functions**: Docstrings required
- **Complex logic**: Inline comments
- **Configuration**: Parameter descriptions
- **APIs**: OpenAPI/Swagger documentation

#### Project Documentation
- **README updates**: For any user-facing changes
- **Architecture docs**: For structural changes
- **Deployment guides**: For new deployment options
- **Troubleshooting**: For common issues

### Documentation Format

#### Docstring Format
```python
def calculate_user_metrics(
    user_data: List[Dict[str, Any]], 
    date_range: Tuple[datetime, datetime]
) -> Dict[str, float]:
    """Calculate user engagement metrics for the specified date range.
    
    This function processes user activity data and calculates key engagement
    metrics including daily active users, session duration, and retention rates.
    
    Args:
        user_data: List of user activity dictionaries containing:
            - user_id (str): Unique user identifier
            - timestamp (datetime): Activity timestamp
            - action (str): Type of user action
            - duration (float): Session duration in seconds
        date_range: Tuple of (start_date, end_date) for analysis period
    
    Returns:
        Dictionary containing calculated metrics:
            - daily_active_users (float): Average DAU in period
            - avg_session_duration (float): Average session length in minutes
            - retention_rate (float): 7-day retention rate as percentage
    
    Raises:
        ValueError: If date_range is invalid or user_data is empty
        TypeError: If user_data elements don't match expected schema
    
    Example:
        >>> users = [{"user_id": "123", "timestamp": datetime.now(), ...}]
        >>> date_range = (datetime(2023, 1, 1), datetime(2023, 1, 31))
        >>> metrics = calculate_user_metrics(users, date_range)
        >>> print(f"DAU: {metrics['daily_active_users']}")
    """
    pass
```

#### Markdown Documentation
```markdown
# Component Name

Brief description of what this component does.

## Overview

Detailed explanation of the component's purpose and role in the system.

## Architecture

Diagram or description of how the component fits into the overall architecture.

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `LOG_LEVEL` | Logging level | `INFO` | No |
| `DATABASE_URL` | Database connection string | None | Yes |

### Example Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "DEBUG"
  DATABASE_URL: "postgresql://..."
```

## Usage

Step-by-step instructions for using the component.

## Troubleshooting

Common issues and their solutions.
```

## 🔍 Submitting Changes

### Pull Request Guidelines

#### Before Submitting
- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] Commits are well-formed
- [ ] No merge conflicts

#### PR Template
```markdown
## Description
Brief description of the changes made.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Performance impact assessed

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally
```

#### Commit Message Format
```
type(scope): short description

Longer description if needed.

Fixes #123
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(api): add user authentication endpoint

Add JWT-based authentication with login/logout endpoints.
Includes rate limiting and security headers.

Fixes #123
```

```
fix(monitoring): resolve Prometheus scraping timeout

Increase scraping timeout from 10s to 30s to handle
slow metric collection during peak load.

Fixes #456
```

### Security Considerations

#### Sensitive Information
- **Never commit secrets** (passwords, API keys, certificates)
- **Use environment variables** for configuration
- **Review dependencies** for vulnerabilities
- **Scan container images** before pushing

#### Security Testing
```bash
# Check for secrets in commits
git secrets --scan

# Scan Python dependencies
safety check

# Scan container images
trivy image your-image:tag

# Run security tests
make security-check
```

## 👀 Review Process

### Review Criteria

#### Code Quality
- Follows established patterns
- Proper error handling
- Adequate test coverage
- Clear and maintainable

#### Security Review
- No hardcoded secrets
- Proper input validation
- Secure defaults
- Minimal attack surface

#### Performance Review
- Efficient algorithms
- Appropriate caching
- Resource usage
- Scalability considerations

#### Documentation Review
- Clear and accurate
- Complete coverage
- Good examples
- Updated architecture

### Review Timeline

- **Initial Review**: Within 2 business days
- **Follow-up**: Within 1 business day
- **Final Approval**: When all criteria met

### Reviewer Responsibilities

#### For Reviewers
- Provide constructive feedback
- Check functional correctness
- Verify test coverage
- Ensure documentation quality
- Consider security implications

#### For Contributors
- Address feedback promptly
- Ask questions if unclear
- Update based on suggestions
- Maintain patience during process

## 🎯 Contribution Areas

### High Priority Areas

1. **Security Enhancements**
   - Additional security scanning
   - Runtime security monitoring
   - Compliance frameworks

2. **Performance Optimization**
   - Application performance tuning
   - Resource optimization
   - Caching strategies

3. **Monitoring & Observability**
   - Additional metrics
   - Custom dashboards
   - Alert rule improvements

4. **Testing & Quality**
   - Increased test coverage
   - Performance testing
   - Chaos engineering

5. **Documentation**
   - User guides
   - Troubleshooting guides
   - Video tutorials

### Getting Help

#### Communication Channels
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Documentation**: Comprehensive guides and references

#### Mentorship
- New contributors welcome
- Pair programming sessions available
- Code review guidance provided
- Architecture discussions encouraged

## 🏆 Recognition

### Contributor Recognition
- Contributors listed in README
- Special recognition for significant contributions
- Opportunity to become project maintainer
- Speaking opportunities at conferences

### Contribution Types Valued
- Code contributions
- Documentation improvements
- Bug reports and testing
- Community support
- Educational content
- Process improvements

---

Thank you for contributing to the Enterprise DevOps Pipeline! Your efforts help make this project better for everyone. 🚀

**Questions?** Feel free to open an issue or start a discussion. We're here to help! 