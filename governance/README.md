# Governance Framework

## Overview

This comprehensive governance framework implements enterprise-grade security, access control, and resource management for OpenShift/Kubernetes environments. It provides a complete solution for managing RBAC, resource quotas, network security, and compliance policies.

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Governance Framework                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │    RBAC     │  │  Resources  │  │  Security   │     │
│  │             │  │             │  │             │     │
│  │ • Roles     │  │ • Quotas    │  │ • Network   │     │
│  │ • Bindings  │  │ • Limits    │  │ • Policies  │     │
│  │ • Groups    │  │ • Classes   │  │ • Scanning  │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ Compliance  │  │ Monitoring  │  │ Automation  │     │
│  │             │  │             │  │             │     │
│  │ • CIS       │  │ • Metrics   │  │ • Scripts   │     │
│  │ • NIST      │  │ • Auditing  │  │ • Validation│     │
│  │ • SOC 2     │  │ • Alerting  │  │ • Health    │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
```

## 📁 Directory Structure

```
governance/
├── rbac/                           # Role-Based Access Control
│   ├── roles.yaml                  # Comprehensive role definitions
│   └── rolebindings.yaml          # User and group assignments
├── resources/                      # Resource Management
│   ├── resource-quotas.yaml       # Namespace resource limits
│   └── limit-ranges.yaml          # Pod/container resource defaults
├── security/                      # Security Policies
│   ├── network-policies.yaml      # Zero-trust networking
│   ├── pod-security-standards.yaml # Pod security enforcement
│   └── security-scanning.yaml     # Security tools deployment
├── scripts/                       # Automation
│   └── setup-governance.sh        # Deployment automation
└── README.md                      # This documentation
```

## 🔐 Role-Based Access Control (RBAC)

### Role Definitions

Our RBAC implementation provides granular access control through seven distinct roles:

#### 1. **Developer Role** (`developer`)
- **Scope**: Namespace-level (development environments)
- **Permissions**: Full CRUD access to application resources
- **Use Case**: Development teams working in dev/staging environments
- **Resources**: Pods, Services, ConfigMaps, Secrets, Deployments, Routes

#### 2. **QA Tester Role** (`qa-tester`)
- **Scope**: Namespace-level (staging environments)
- **Permissions**: Read access + limited testing capabilities
- **Use Case**: Quality assurance and testing teams
- **Resources**: Read-only access to most resources, limited secret access

#### 3. **DevOps Engineer Role** (`devops-engineer`)
- **Scope**: Cluster-level
- **Permissions**: Full infrastructure management
- **Use Case**: Platform engineering and infrastructure management
- **Resources**: All Kubernetes resources, RBAC management, CRDs

#### 4. **Site Reliability Engineer Role** (`sre`)
- **Scope**: Cluster-level
- **Permissions**: Production monitoring and troubleshooting
- **Use Case**: Incident response and production support
- **Resources**: Read access + emergency management capabilities

#### 5. **Security Auditor Role** (`security-auditor`)
- **Scope**: Cluster-level
- **Permissions**: Read-only access for compliance
- **Use Case**: Security auditing and compliance checking
- **Resources**: Full read access to all security-related resources

#### 6. **CI/CD Service Role** (`cicd-service`)
- **Scope**: Cluster-level
- **Permissions**: Automated deployment capabilities
- **Use Case**: Continuous integration and deployment pipelines
- **Resources**: Deployment resources, limited secret access

#### 7. **Read-Only Role** (`readonly-user`)
- **Scope**: Cluster-level
- **Permissions**: Basic viewing permissions
- **Use Case**: Stakeholders and external auditors
- **Resources**: Common resources without sensitive data access

### User Assignment Examples

```yaml
# Development team access
subjects:
  - kind: User
    name: john.developer@company.com
  - kind: Group
    name: developers

# Production administrators
subjects:
  - kind: User
    name: prod.admin@company.com
  - kind: Group
    name: prod-admins
```

## 💾 Resource Management

### Resource Quotas by Environment

Our resource quota system implements progressive restrictions based on environment criticality:

#### Development Environment
- **CPU**: 4 cores request, 8 cores limit
- **Memory**: 8GB request, 16GB limit
- **Storage**: 100GB total
- **Pods**: 20 maximum
- **Philosophy**: Generous allocation for development productivity

#### Staging Environment
- **CPU**: 8 cores request, 16 cores limit
- **Memory**: 16GB request, 32GB limit
- **Storage**: 200GB total
- **Pods**: 30 maximum
- **Philosophy**: Production-like resources for realistic testing

#### Production Environment
- **CPU**: 20 cores request, 40 cores limit
- **Memory**: 40GB request, 80GB limit
- **Storage**: 500GB total
- **Pods**: 50 maximum
- **Philosophy**: High availability and performance

### Limit Ranges

Container-level defaults and limits ensure:
- **Resource Efficiency**: Prevent resource waste
- **Fair Sharing**: Ensure no single container monopolizes resources
- **Predictable Performance**: Consistent resource allocation
- **Cost Control**: Budget predictability

#### Example Container Limits
```yaml
# Production container defaults
default:
  cpu: "1"
  memory: "1Gi"
  ephemeral-storage: "4Gi"
max:
  cpu: "4"
  memory: "8Gi"
  ephemeral-storage: "20Gi"
```

## 🛡️ Security Framework

### Network Security (Zero-Trust Model)

Our network policies implement a zero-trust security model:

#### Default Deny Policy
- All traffic denied by default
- Explicit allow rules required
- Principle of least privilege

#### Microservice Communication
```yaml
# Allow specific ingress only
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            name: openshift-ingress
    ports:
      - protocol: TCP
        port: 8080
```

#### Environment-Specific Policies
- **Development**: Permissive for productivity
- **Staging**: Moderate restrictions
- **Production**: Strict zero-trust enforcement

### Pod Security Standards

Implementation of Kubernetes Pod Security Standards:

#### Production (Restricted)
- Non-root execution mandatory
- Read-only root filesystem
- All capabilities dropped
- seccomp profile enforced

#### Staging (Baseline)
- Non-root execution
- Limited capabilities allowed
- Moderate security restrictions

#### Development (Privileged)
- Relaxed security for development
- Debug capabilities available
- Flexible volume mounting

### Security Context Constraints (OpenShift)

Custom SCCs for different security profiles:

```yaml
# Restricted SCC example
allowPrivilegeEscalation: false
runAsUser:
  type: MustRunAsNonRoot
readOnlyRootFilesystem: true
requiredDropCapabilities:
  - ALL
```

## 🔍 Security Scanning & Compliance

### Integrated Security Tools

#### 1. **Trivy Scanner**
- Vulnerability scanning for container images
- High-availability deployment with persistent cache
- Integration with CI/CD pipelines

#### 2. **Falco Runtime Security**
- Real-time threat detection
- Behavioral analysis of running containers
- Kubernetes audit log monitoring

#### 3. **Kube-bench**
- CIS Kubernetes Benchmark compliance
- Automated weekly security assessments
- Detailed compliance reporting

#### 4. **OPA Gatekeeper**
- Policy-as-code enforcement
- Custom constraint definitions
- Admission control validation

### Compliance Frameworks

#### CIS Kubernetes Benchmark
- API server security configuration
- Authentication and authorization
- Network policy enforcement

#### NIST SP 800-190
- Container image security
- Runtime protection
- Infrastructure security

#### SOC 2 Type II
- Access controls
- System monitoring
- Change management

## 🚀 Quick Start

### Prerequisites

- OpenShift 4.x or Kubernetes 1.20+
- Cluster admin privileges
- `oc` or `kubectl` CLI tools

### Deployment

```bash
# Clone the repository
git clone <repository-url>
cd governance

# Deploy the complete governance framework
./scripts/setup-governance.sh deploy

# Perform dry run to see what would be deployed
./scripts/setup-governance.sh deploy --dry-run

# Check deployment health
./scripts/setup-governance.sh health

# Validate RBAC configuration
./scripts/setup-governance.sh validate
```

### Verification

```bash
# Check namespace creation
oc get namespaces | grep microservice-demo

# Verify RBAC roles
oc get clusterroles | grep -E "(devops-engineer|sre|security-auditor)"

# Check resource quotas
oc get resourcequota -A

# Verify network policies
oc get networkpolicy -A

# Check security tools
oc get pods -n security-tools
```

## 🔧 Customization

### Adding New Roles

1. **Define the role** in `rbac/roles.yaml`:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: custom-role
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

2. **Create role binding** in `rbac/rolebindings.yaml`:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: custom-role-binding
subjects:
  - kind: User
    name: user@company.com
roleRef:
  kind: ClusterRole
  name: custom-role
```

### Environment-Specific Configuration

Modify resource quotas for your environment:
```yaml
# Adjust CPU/Memory limits in resource-quotas.yaml
spec:
  hard:
    requests.cpu: "YOUR_CPU_LIMIT"
    requests.memory: YOUR_MEMORY_LIMIT
```

### Custom Security Policies

Add organization-specific network policies:
```yaml
# Custom network policy example
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: custom-policy
spec:
  # Your policy configuration
```

## 📊 Monitoring & Alerting

### Governance Metrics

The framework exposes metrics for:
- **RBAC Violations**: Unauthorized access attempts
- **Resource Usage**: Quota utilization by namespace
- **Security Events**: Policy violations and threats
- **Compliance Status**: Benchmark adherence scores

### Integration with Observability Stack

```yaml
# Prometheus ServiceMonitor for governance metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: governance-metrics
spec:
  selector:
    matchLabels:
      app: security-metrics-exporter
```

### Alerting Rules

```yaml
# Example alerting rule for quota exhaustion
- alert: NamespaceQuotaExhausted
  expr: |
    kube_resourcequota{resource="requests.cpu", type="used"} / 
    kube_resourcequota{resource="requests.cpu", type="hard"} > 0.9
  for: 5m
  labels:
    severity: warning
```

## 🔄 Maintenance & Operations

### Regular Tasks

#### Weekly
- Review security scan results
- Update vulnerability databases
- Audit access logs

#### Monthly
- Review and update RBAC assignments
- Analyze resource utilization trends
- Update compliance reports

#### Quarterly
- Comprehensive security assessment
- Policy review and updates
- Disaster recovery testing

### Troubleshooting

#### Common Issues

**RBAC Access Denied**
```bash
# Check user permissions
oc auth can-i get pods --as=user@company.com -n namespace

# Review role bindings
oc describe rolebinding binding-name -n namespace
```

**Resource Quota Exceeded**
```bash
# Check quota usage
oc describe resourcequota -n namespace

# View resource consumption
oc top pods -n namespace
```

**Network Policy Blocking Traffic**
```bash
# List network policies
oc get networkpolicy -n namespace

# Test connectivity
oc run test-pod --image=busybox -it --rm -- /bin/sh
```

### Backup and Recovery

```bash
# Backup RBAC configuration
oc get clusterroles,clusterrolebindings -o yaml > rbac-backup.yaml

# Backup resource quotas
oc get resourcequota -A -o yaml > quotas-backup.yaml

# Backup network policies
oc get networkpolicy -A -o yaml > network-policies-backup.yaml
```

## 📚 Best Practices

### Security
1. **Principle of Least Privilege**: Grant minimum required permissions
2. **Regular Auditing**: Review access patterns and permissions
3. **Network Segmentation**: Use network policies extensively
4. **Image Security**: Scan all container images before deployment

### Resource Management
1. **Right-sizing**: Monitor and adjust resource limits regularly
2. **Environment Parity**: Keep staging close to production
3. **Cost Optimization**: Use resource quotas to control cloud costs
4. **Performance Monitoring**: Track resource utilization trends

### Operational Excellence
1. **Infrastructure as Code**: Version control all configurations
2. **Automated Testing**: Validate policies in CI/CD pipelines
3. **Documentation**: Keep governance policies well-documented
4. **Change Management**: Follow controlled change processes

## 🤝 Contributing

### Adding New Features

1. **Propose Changes**: Create an issue describing the enhancement
2. **Develop**: Implement changes following existing patterns
3. **Test**: Validate changes in development environment
4. **Document**: Update this README and inline documentation
5. **Review**: Submit pull request for team review

### Testing Framework

```bash
# Run dry run deployment
./scripts/setup-governance.sh deploy --dry-run

# Validate RBAC configuration
./scripts/setup-governance.sh validate

# Perform health checks
./scripts/setup-governance.sh health
```

## 📋 Checklist for Production Deployment

- [ ] Review all role definitions for your organization
- [ ] Customize resource quotas for your cluster capacity
- [ ] Update user/group assignments in role bindings
- [ ] Configure network policies for your network architecture
- [ ] Set up monitoring and alerting integration
- [ ] Schedule regular security scans and compliance checks
- [ ] Establish backup and recovery procedures
- [ ] Train teams on new governance policies
- [ ] Document incident response procedures
- [ ] Plan regular governance policy reviews

## 🆘 Support & Resources

### Internal Documentation
- RBAC Policy Guide: [Link to internal docs]
- Resource Management Playbook: [Link to internal docs]
- Security Incident Response: [Link to internal docs]

### External Resources
- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [OpenShift Security Guide](https://docs.openshift.com/container-platform/latest/security/index.html)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NIST Container Security Guide](https://csrc.nist.gov/publications/detail/sp/800-190/final)

### Contact Information
- **DevOps Team**: devops@company.com
- **Security Team**: security@company.com
- **Platform Team**: platform@company.com

---

**Last Updated**: $(date)
**Version**: 1.0
**Maintainers**: DevOps & Security Teams 