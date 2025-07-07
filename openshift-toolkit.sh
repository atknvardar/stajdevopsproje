#!/bin/bash
# OpenShift CI/CD Toolkit

echo "🚀 OPENSHIFT CI/CD TOOLKIT"
echo "=========================="

function deploy_app() {
    local app_name=${1:-microservice-demo}
    local image=${2:-nginx:latest}
    local namespace=${3:-microservice-cicd}
    
    echo "📦 Deploying $app_name..."
    oc create deployment $app_name --image=$image --replicas=1 -n $namespace
    oc expose deployment $app_name --port=80 --target-port=80 -n $namespace
    oc rollout status deployment/$app_name -n $namespace
    echo "✅ Deployment completed!"
}

function check_status() {
    local app_name=${1:-microservice-demo}
    local namespace=${2:-microservice-cicd}
    
    echo "🔍 Status for $app_name:"
    oc get all -l app=$app_name -n $namespace
}

function scale_app() {
    local app_name=${1:-microservice-demo}
    local replicas=${2:-2}
    local namespace=${3:-microservice-cicd}
    
    echo "�� Scaling $app_name to $replicas replicas..."
    oc scale deployment $app_name --replicas=$replicas -n $namespace
    oc rollout status deployment/$app_name -n $namespace
}

function delete_app() {
    local app_name=${1:-microservice-demo}
    local namespace=${2:-microservice-cicd}
    
    echo "🗑️ Deleting $app_name..."
    oc delete all -l app=$app_name -n $namespace
}

function run_pipeline() {
    echo "🔄 Running OpenShift CI/CD Pipeline..."
    kubectl create -f - <<YAML
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: openshift-cicd-
  namespace: microservice-cicd
spec:
  pipelineRef:
    name: openshift-cicd-pipeline
  params:
    - name: git-url
      value: https://github.com/atknvardar/stajdevopsproje.git
    - name: git-revision
      value: main
    - name: app-name
      value: microservice-demo
  workspaces:
    - name: shared-workspace
      persistentVolumeClaim:
        claimName: pipeline-workspace-pvc
YAML
    echo "✅ Pipeline started!"
}

echo "📋 Available commands:"
echo "  deploy_app [name] [image] [namespace]"
echo "  check_status [name] [namespace]"
echo "  scale_app [name] [replicas] [namespace]"
echo "  delete_app [name] [namespace]"
echo "  run_pipeline"
echo ""
echo "🎯 Examples:"
echo "  deploy_app my-app nginx:latest microservice-cicd"
echo "  check_status openshift-demo"
echo "  scale_app openshift-demo 3"
