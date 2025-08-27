#!/bin/bash
# k8s-deploy.sh
# Kubernetes deployment script

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --environment)
      ENVIRONMENT="$2"
      shift
      shift
      ;;
    --image-tag)
      IMAGE_TAG="$2"
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
    --service-type)
      SERVICE_TYPE="$2"
      shift
      shift
      ;;
    --domain)
      DOMAIN="$2"
      shift
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Generate Kubernetes manifest
cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $REPO_NAME
  namespace: $PROJECT_NAME
  labels:
    app: $REPO_NAME
    environment: $ENVIRONMENT
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $REPO_NAME
  template:
    metadata:
      labels:
        app: $REPO_NAME
        environment: $ENVIRONMENT
    spec:
      containers:
        - name: $REPO_NAME
          image: $HARBOR_REGISTRY/$SERVICE_TYPE:$IMAGE_TAG
          ports:
            - containerPort: 8080
      env:
        - name: SPRING_PROFILES_ACTIVE
          value: $ENVIRONMENT
---
apiVersion: v1
kind: Service
metadata:
  name: $REPO_NAME-service
  namespace: $PROJECT_NAME
spec:
  selector:
    app: $REPO_NAME
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $REPO_NAME-ingress
  namespace: $PROJECT_NAME
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  rules:
    - host: $IMAGE_TAG.$SERVICE_TYPE.$DOMAIN
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: $REPO_NAME-service
                port:
                  number: 80
  tls:
    - hosts:
        - $IMAGE_TAG.$SERVICE_TYPE.$DOMAIN
      secretName: $REPO_NAME-tls
EOF

# Apply the manifest
kubectl apply -f deployment.yaml