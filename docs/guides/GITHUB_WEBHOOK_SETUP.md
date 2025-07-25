# GitHub Webhook Setup Guide

## Webhook Configuration

Your OpenShift BuildConfig is now configured to accept GitHub webhooks. Follow these steps to complete the setup:

### 1. Webhook Details

- **Webhook URL**: `https://api.crc.testing:6443/apis/build.openshift.io/v1/namespaces/weather-app/buildconfigs/weather-app/webhooks/1af2d790014a6ae85ccb4638f6a850322d14789e/github`
- **Secret**: `1af2d790014a6ae85ccb4638f6a850322d14789e`
- **Content Type**: `application/json`

### 2. GitHub Repository Setup

1. Go to your GitHub repository
2. Navigate to **Settings** → **Webhooks**
3. Click **Add webhook**
4. Configure as follows:
   - **Payload URL**: Use the webhook URL above
   - **Content type**: `application/json`
   - **Secret**: `1af2d790014a6ae85ccb4638f6a850322d14789e`
   - **SSL verification**: Disable (for local CRC)
   - **Which events**: Select "Just the push event"
5. Click **Add webhook**

### 3. Testing the Webhook

After setup, test by:
1. Making a small change to your code
2. Committing and pushing to GitHub
3. Check OpenShift for automatic build trigger:
   ```bash
   oc get builds -w
   ```

### 4. For Public GitHub Access

If your CRC instance is not publicly accessible, you have options:

#### Option A: Use ngrok (Recommended for testing)
```bash
# Install ngrok
brew install ngrok

# Expose your API
ngrok http https://api.crc.testing:6443

# Use the ngrok URL in GitHub webhook instead
```

#### Option B: Use GitHub Actions
Create `.github/workflows/openshift-build.yml`:
```yaml
name: Trigger OpenShift Build
on:
  push:
    branches: [ main ]

jobs:
  trigger-build:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger OpenShift Build
        run: |
          curl -k -X POST \
            -H "Content-Type: application/json" \
            -d '{"type":"github","github":{}}' \
            https://api.crc.testing:6443/apis/build.openshift.io/v1/namespaces/weather-app/buildconfigs/weather-app/webhooks/1af2d790014a6ae85ccb4638f6a850322d14789e/generic
```

### 5. Manual Webhook Testing

Test the webhook locally:
```bash
# Generic webhook URL (no auth needed)
curl -k -X POST \
  https://api.crc.testing:6443/apis/build.openshift.io/v1/namespaces/weather-app/buildconfigs/weather-app/webhooks/1PH_luEklVza0oohD4oc/generic \
  -H "Content-Type: application/json" \
  -d '{"message": "Manual trigger"}'
```

### 6. Troubleshooting

Check webhook deliveries:
- GitHub: Settings → Webhooks → Recent Deliveries
- OpenShift: `oc logs -f bc/weather-app`

Verify webhook configuration:
```bash
oc get bc weather-app -o yaml | grep -A10 triggers
```

Monitor builds:
```bash
# Watch for new builds
oc get builds -w

# View build logs
oc logs -f bc/weather-app
```