# Workflows Documentation

This document outlines the CI/CD workflows and their purposes.

## 1. **Main CI/CD Workflow** (`common-ci-cd.yml`)

- **Purpose**: The main pipeline that orchestrates the CI/CD steps, including build, test, security scan, and deployment.
- **Trigger**: Triggered on `push` to any branch or tag.
- **Key Jobs**:
  - `call-preview`: Runs for feature branches.
  - `call-stage`: Runs for the `main` branch.
  - `call-live`: Runs for tag pushes.
  - `call-data-migration`: Runs for data migrations.

## 2. **Preview Workflow** (`preview.yml`)

- **Purpose**: Creates and deploys the preview environment for feature branches.
- **Trigger**: Triggered on feature branch push.
- **Key Jobs**:
  - `preview`: Builds and deploys the preview environment.
  - `e2e-tests`: Runs Playwright E2E tests on the preview environment.

## 3. **Stage Workflow** (`stage.yml`)

- **Purpose**: Creates and deploys the stage environment after merging to the `main` branch.
- **Trigger**: Triggered on `main` branch merge.
- **Key Jobs**:
  - `stage`: Deploys to the stage environment.
  - `e2e-tests`: Runs Playwright E2E tests on the stage environment.

## 4. **Live Workflow** (`live.yml`)

- **Purpose**: Creates and deploys the live (production) environment when a tag is pushed.
- **Trigger**: Triggered on tag push (e.g., `v1.0.0`).
- **Key Jobs**:
  - `live`: Deploys to the live environment.
  - `smoke-test`: Performs a simple health check on the live environment.

## 5. **Data Migration Workflow** (`data-migration.yml`)

- **Purpose**: Runs data migrations (e.g., Flyway) for databases.
- **Trigger**: Triggered for data projects on `main` branch merge or tag push.
- **Key Jobs**:
  - `data-migration`: Runs the Flyway migrations and validates the database schema.
