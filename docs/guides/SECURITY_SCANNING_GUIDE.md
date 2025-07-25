# Security Scanning Integration Guide

## Overview

Your CI/CD pipeline now includes comprehensive security scanning at multiple stages:

### 1. **Dependency Vulnerability Scanning**
- **Tool**: Safety
- **What it checks**: Python packages for known CVEs
- **When**: During build and post-build
- **Fail criteria**: Critical or High vulnerabilities

### 2. **Static Application Security Testing (SAST)**
- **Tool**: Bandit
- **What it checks**: Python code for security issues
- **When**: During build
- **Fail criteria**: High severity issues

### 3. **License Compliance**
- **Tool**: pip-licenses
- **What it checks**: Package licenses
- **When**: During build
- **Restricted licenses**: GPL, AGPL, LGPL

### 4. **Container Image Scanning**
- **Tool**: Trivy (when available)
- **What it checks**: OS packages and application dependencies
- **When**: Post-build
- **Fail criteria**: Critical vulnerabilities

## Security Build Configurations

### 1. Basic Security Build
```bash
oc start-build weather-app --from-dir=.
```

### 2. Enhanced Security Build
```bash
oc start-build weather-app-with-security --from-dir=.
```

### 3. Manual Security Scan
```bash
./run-security-scan.sh
```

## Current Security Findings

### Vulnerabilities Found:
1. **FastAPI 0.104.1** - CVE-2024-24762
   - Severity: High
   - Fix: Upgrade to fastapi>=0.109.1
   - Issue: python-multipart dependency vulnerability

### Recommended Actions:
1. Update `app/requirements.txt`:
   ```
   fastapi==0.109.1
   ```

2. Run security scan:
   ```bash
   safety check --file app/requirements.txt
   ```

## Security Gates in Pipeline

### Build Phase
- Dependency scanning
- SAST analysis
- License compliance

### Post-Build Phase
- Container image scanning
- Runtime security checks
- Configuration validation

## Security Reports

Reports are generated in the `security-reports/` directory:
- `safety-report.json` - Dependency vulnerabilities
- `bandit-report.json` - Code security issues
- `licenses.json` - License compliance
- `trivy-report.json` - Container vulnerabilities

## Best Practices

1. **Regular Updates**
   - Update dependencies monthly
   - Review security advisories weekly
   - Patch critical vulnerabilities immediately

2. **Secure Coding**
   - Never hardcode secrets
   - Use environment variables for configuration
   - Validate all inputs
   - Use secure random generators

3. **Container Security**
   - Use minimal base images
   - Run as non-root user
   - Remove unnecessary tools
   - Scan images regularly

## Integration with OpenShift

The security scanning is integrated via:
1. BuildConfig with postCommit hooks
2. Automated scanning on each build
3. Build fails on critical issues
4. Reports stored in persistent volumes

## Monitoring Security Metrics

Track these metrics in Prometheus:
- `security_scan_vulnerabilities_total`
- `security_scan_duration_seconds`
- `security_scan_failures_total`
- `security_compliance_score`