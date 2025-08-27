# GitHub Actions Documentation

This document provides an overview of the GitHub Actions used in the CI/CD pipeline.

## 1. Setup Environment
The **Setup Environment** action installs the necessary tools for the pipeline, including Java and Node.js, based on the project requirements.

### Action: `setup-environment`
- **Inputs**: `java-version`, `node-version`
- **Purpose**: Sets up the environment with Java and Node.js for the project.

## 2. Build Java
The **Build Java** action compiles the Java project using Maven or Gradle.

### Action: `build-java`
- **Inputs**: `build-tool`, `java-version`
- **Purpose**: Builds the Java project using the specified build tool (Maven or Gradle).

## 3. Build React
The **Build React** action installs dependencies and builds the React project.

### Action: `build-react`
- **Inputs**: `node-version`
- **Purpose**: Installs dependencies using npm and builds the React project.

## 4. Security Scan
The **Security Scan** action uses Snyk and Trivy to check for vulnerabilities in the code and Docker images.

### Action: `security-scan`
- **Inputs**: `snyk-token`
- **Purpose**: Runs Snyk for code vulnerability scanning and Trivy for image scanning.

## 5. Docker Operations
The **Docker Operations** action builds and pushes Docker images to the registry (e.g., Harbor).

### Action: `docker-operations`
- **Inputs**: `operation`, `harbor-registry`, `docker-tag`
- **Purpose**: Builds and pushes Docker images to the specified registry.

## 6. Kubernetes Deploy
The **Kubernetes Deploy** action deploys the application to a Kubernetes cluster.

### Action: `k8s-deploy`
- **Inputs**: `environment`, `project-name`, `component`, `image-tag`, `kubeconfig`
- **Purpose**: Deploys the application to Kubernetes based on the environment (Preview, Stage, Live).

## 7. DNS Management
The **DNS Management** action updates the DNS records in AWS Route53 for the deployed environment.

### Action: `dns-management`
- **Inputs**: `environment`, `subdomain`, `domain`
- **Purpose**: Creates or updates DNS records in Route53 for the deployed environment.
