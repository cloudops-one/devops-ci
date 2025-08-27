# Environments Documentation

This document outlines the environments used in the CI/CD pipeline and their configurations.

## 1. Preview Environment

The **Preview** environment is created for each feature branch. It is used to test changes before they are merged to the main branch.

### Key Features:

- Created automatically on every feature branch push.
- Namespace: `<feature-branch>-preview`
- DNS: `preview.<feature-branch>.<domain>`
- TTL: 3 hours (auto-expiry and cleanup).
- Automatically deployed with the latest Docker image tagged by the branch name.

## 2. Stage Environment

The **Stage** environment is used to test the application before it is deployed to production. It is deployed automatically when code is merged into the `main` branch.

### Key Features:

- Triggered on a push to the `main` branch.
- Namespace: `stage`
- DNS: `stage.<domain>`
- Uses Docker image tagged as `stage`.

## 3. Live Environment

The **Live** environment is the production environment where the final version of the application is deployed.

### Key Features:

- Triggered on tag pushes (e.g., `v1.0.0`).
- Namespace: `live`
- DNS: `live.<domain>`
- Uses Docker image tagged by version (`v1.0.0`).
- **Automatic rollback** on failure (using Helm or kubectl).

## Environment Protection:

- **Preview**: No approval required.
- **Stage**: Requires 1 approval.
- **Live**: Requires 2 approvals.
