# Setup Guide for CI/CD Workflows

## Prerequisites

1. Ensure you have access to the CloudOps-One GitHub organization.
2. All required secrets (e.g., `HARBOR_USERNAME`, `AWS_ACCESS_KEY_ID`) should be set in the GitHub repository settings.

## Repository Setup

1. Clone the `cloudops-one` repository to get access to shared workflows and actions.
2. Add the necessary project configurations under `project-repos/` for your project.
3. Each project repository should reference the main pipeline from `cloudops-one/devops-ci/.github/workflows/main-pipeline.yml`.

## Workflow Configuration

### Preview Environment

- Triggered on branch pushes (e.g., `feat-123_branch-name`).
- Deploys to Kubernetes with a TTL of 3 hours.

### Stage Environment

- Triggered on merge to `main`.
- Deploys to the `stage` namespace in Kubernetes.

### Live Environment

- Triggered on tag push (e.g., `v1.0.0`).
- Deploys to the `live` namespace in Kubernetes.
