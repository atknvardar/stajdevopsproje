#!/bin/bash

echo "🚀 Deploying Weather App to All Environments"
echo "==========================================="

# Function to create namespace if it doesn't exist
create_namespace() {
    local ns=$1
    if ! oc get namespace $ns &>/dev/null; then
        echo "📁 Creating namespace: $ns"
        oc create namespace $ns
        oc label namespace $ns environment=$ns
    else
        echo "✅ Namespace $ns already exists"
    fi
}

# Deploy to each environment
deploy_environment() {
    local env=$1
    local namespace="weather-app-$env"
    
    echo ""
    echo "🔧 Deploying to $env environment..."
    
    # Create namespace
    create_namespace $namespace
    
    # Apply kustomize overlay
    echo "📦 Applying $env overlay..."
    oc apply -k openshift/overlays/$env/ -n $namespace
    
    # Wait for deployment
    echo "⏳ Waiting for deployment to be ready..."
    oc wait --for=condition=available --timeout=300s deployment/microservice-demo-$env -n $namespace || true
    
    # Get route
    ROUTE=$(oc get route microservice-demo-$env -n $namespace -o jsonpath='{.spec.host}' 2>/dev/null || echo "No route found")
    echo "🌐 Route: http://$ROUTE"
}

# Check current status
echo "📊 Current Deployment Status:"
echo "-----------------------------"
oc get deployments,services,routes -n weather-app

# Deploy to all environments
for env in dev staging prod; do
    deploy_environment $env
done

echo ""
echo "📋 Deployment Summary:"
echo "====================="
for env in dev staging prod; do
    namespace="weather-app-$env"
    echo ""
    echo "$env environment ($namespace):"
    oc get deployments,pods,services,routes -n $namespace 2>/dev/null || echo "  ❌ Not deployed"
done

echo ""
echo "✅ Deployment process complete!"
echo ""
echo "🔍 To check individual environments:"
echo "  oc project weather-app-dev"
echo "  oc project weather-app-staging"
echo "  oc project weather-app-prod"