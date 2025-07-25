# 🖥️ OpenShift Console Visual Guide

## Access Console
URL: https://console-openshift-console.apps-crc.testing

## 🗺️ Console Navigation Map

```
OpenShift Console
├── 👨‍💼 Administrator Perspective
│   ├── Home
│   │   ├── Overview → Cluster health, resource usage
│   │   ├── Search → Find any resource
│   │   └── Events → Cluster-wide events
│   │
│   ├── Workloads
│   │   ├── Pods → Running containers
│   │   ├── Deployments → Your applications ⭐
│   │   ├── ReplicaSets → Pod replicas
│   │   ├── StatefulSets → Stateful apps
│   │   └── Jobs → One-time tasks
│   │
│   ├── Networking
│   │   ├── Services → Internal networking
│   │   ├── Routes → External URLs ⭐
│   │   └── NetworkPolicies → Traffic rules
│   │
│   ├── Storage
│   │   ├── PersistentVolumeClaims
│   │   └── StorageClasses
│   │
│   ├── Builds
│   │   ├── BuildConfigs → CI/CD pipelines ⭐
│   │   ├── ImageStreams → Container images ⭐
│   │   └── Builds → Build history
│   │
│   └── User Management
│       ├── RoleBindings → Permissions ⭐
│       ├── ServiceAccounts → App identities
│       └── Roles → Permission sets
│
└── 👨‍💻 Developer Perspective
    ├── +Add → Deploy new applications
    ├── Topology → Visual app diagram ⭐
    ├── Observe
    │   ├── Metrics → Prometheus graphs
    │   ├── Alerts → Alert rules
    │   └── Dashboards → Grafana
    ├── Builds → See your builds
    ├── Pipelines → Tekton CI/CD
    └── Project → Switch projects

⭐ = Key areas for your platform
```

## 📍 Step-by-Step Console Tour

### 1. First Login
```
1. Open: https://console-openshift-console.apps-crc.testing
2. Login with: kubeadmin / (your password)
3. You'll see the Administrator perspective by default
```

### 2. Navigate to Your Project
```
Top bar → Project dropdown → Select "devops-platform"
```

### 3. View Your Application (Developer Perspective)
```
1. Click "Developer" in the left menu
2. Click "Topology"
3. You'll see your microservice as a circle
4. Click the circle to see details
5. Click the arrow icon to visit the app
```

### 4. Check Deployments (Administrator Perspective)
```
1. Switch back to "Administrator"
2. Workloads → Deployments
3. Click "microservice"
4. See: Replicas, Image, Resources, Conditions
5. Click "Pods" tab to see running pods
6. Click "Events" tab for recent activities
```

### 5. View External Routes
```
1. Networking → Routes
2. Click "microservice"
3. See the URL under "Location"
4. Note "TLS Settings" shows edge termination
```

### 6. Check Builds
```
1. Builds → BuildConfigs
2. Click "microservice"
3. See build strategy and triggers
4. Click "Builds" tab for history
5. Click "Start Build" to trigger new build
```

### 7. Monitor Resources
```
1. Home → Search
2. Type: "ResourceQuota"
3. Click "compute-quota"
4. See resource usage vs limits
```

### 8. View Logs
```
1. Workloads → Pods
2. Click any running pod
3. Click "Logs" tab
4. Toggle "streaming" for real-time
```

## 🎯 Quick Actions in Console

### Scale Application
```
Workloads → Deployments → microservice → YAML
Change: replicas: 1 → replicas: 2
Click: Save
```

### Trigger Build
```
Builds → BuildConfigs → microservice
Click: Actions → Start Build
```

### View Metrics
```
Developer perspective → Observe → Metrics
Query: container_memory_usage_bytes{pod=~"microservice.*"}
```

### Check Events
```
Home → Events
Filter by: devops-platform project
```

## 🖼️ Key Console Sections for Your Platform

### 1. Topology View (Developer)
Shows your microservice with:
- Pod status (green = running)
- Build status
- Route link
- Resource decorators

### 2. Deployment Details (Administrator)
Shows:
- Current/Desired replicas
- Update strategy
- Pod template
- Environment variables
- Resource limits

### 3. Build History
Shows:
- Build number
- Status (Complete/Failed)
- Duration
- Triggered by

### 4. Pod Logs
Shows:
- Container output
- Application logs
- Error messages
- Real-time streaming

### 5. Metrics Dashboard
Shows:
- CPU usage
- Memory usage
- Network traffic
- Custom app metrics

## 🔍 Console Search Tips

Use the search bar to quickly find:
- `kind:Deployment` - All deployments
- `kind:Route` - All routes
- `kind:Pod status:Running` - Running pods
- `label:app=microservice` - Resources with label

## 📱 Console Features

### Dark Mode
Profile → User Preferences → Theme → Dark

### Terminal Access
Workloads → Pods → [Select Pod] → Terminal tab

### YAML Editor
Any resource → YAML tab → Edit with syntax highlighting

### Resource Creation
+Add → YAML → Paste manifests → Create

## 🎓 Learning Resources in Console

### Guided Tours
Help → Guided Tours → Start tour

### Quick Starts
Help → Quick Starts → Follow tutorials

### Documentation Links
Help → Documentation → OpenShift docs

## 💡 Pro Tips

1. **Bookmark Important Views**
   - Your topology page
   - Deployment list
   - Build configs

2. **Use Filters**
   - Filter by labels
   - Filter by status
   - Save filter presets

3. **Keyboard Shortcuts**
   - `/` - Focus search
   - `?` - Show shortcuts
   - `Ctrl+K` - Quick switcher

4. **Custom Columns**
   - Click gear icon in lists
   - Select columns to display
   - Save preferences

## 🚀 Next Steps

1. **Run the interactive tour:**
   ```bash
   ./openshift-detailed-tour.sh
   ```

2. **Explore each section:**
   - Start with Topology view
   - Check your deployments
   - View build history
   - Examine routes

3. **Try making changes:**
   - Scale your app
   - Trigger a build
   - View real-time logs

Remember: The console is your window into OpenShift. Explore freely - you can't break anything by looking!