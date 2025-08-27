#!/bin/bash
# rollback.sh
# Rollback Kubernetes deployment to the previous version

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --environment)
      ENVIRONMENT="$2"
      shift
      shift
      ;;
    --project-name)
      PROJECT_NAME="$2"
      shift
      shift
      ;;
    --repo-name)
      REPO_NAME="$2"
      shift
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Rollback deployment using kubectl
kubectl rollout undo deployment/$REPO_NAME -n $PROJECT_NAME

# Notify successful rollback
echo "Rollback completed successfully for $REPO_NAME in $PROJECT_NAME"