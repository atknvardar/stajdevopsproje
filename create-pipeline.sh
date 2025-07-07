#!/bin/bash
# Quick CLI Pipeline Creator

echo "🚀 Creating new pipeline run..."

kubectl create -f - <<YAML
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: cli-pipeline-
  namespace: microservice-cicd
  labels:
    trigger: cli-script
spec:
  pipelineRef:
    name: microservice-complete-pipeline
  params:
    - name: git-url
      value: https://github.com/atknvardar/stajdevopsproje.git
    - name: git-revision
      value: main
  workspaces:
    - name: shared-workspace
      persistentVolumeClaim:
        claimName: pipeline-workspace-pvc
YAML

echo "✅ Pipeline created! Monitor with:"
echo "kubectl get pipelinerun -l trigger=cli-script -n microservice-cicd -w"
