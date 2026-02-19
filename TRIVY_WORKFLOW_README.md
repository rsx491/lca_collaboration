# 🛡️ Trivy Security Scanning Workflow

This repository uses **Trivy (by Aqua Security)** to automatically scan
the project for security issues.

## What This Workflow Does

The Trivy GitHub Action performs:

-   🔍 Vulnerability scanning (HIGH & CRITICAL)
-   🔐 Secret detection
-   ⚙️ Infrastructure misconfiguration scanning
-   🐳 Docker image vulnerability scanning
-   📦 SBOM (Software Bill of Materials) generation

The workflow file is located at:

    .github/workflows/trivy.yml

------------------------------------------------------------------------

## When It Runs

The workflow automatically runs on:

-   Every push to the `main` branch
-   Every pull request
-   Manual trigger via GitHub Actions UI

------------------------------------------------------------------------

## 1️⃣ Repository Scan (Filesystem Scan)

Scans the full repository for:

-   Known CVEs
-   Hardcoded secrets
-   Configuration risks (Docker, YAML, etc.)

Results are: - Uploaded to **GitHub Code Scanning** - Stored as an
artifact (`trivy-fs.sarif`)

------------------------------------------------------------------------

## 2️⃣ SBOM Generation

The workflow generates a **CycloneDX SBOM file**:

    sbom.cdx.json

This file lists all detected components and dependencies.

The SBOM is uploaded as a downloadable artifact.

------------------------------------------------------------------------

## 3️⃣ Docker Image Scan

The workflow:

1.  Builds the Docker image
2.  Scans the image for HIGH and CRITICAL vulnerabilities
3.  Uploads results to GitHub Code Scanning
4.  Stores results as an artifact

------------------------------------------------------------------------

## Where to View Results

### Code Scanning Alerts

Go to:

Security → Code scanning alerts

### Workflow Artifacts

Go to:

Actions → Select workflow run → Artifacts

You can download: - `trivy-fs.sarif` - `trivy-image.sarif` -
`sbom-cyclonedx`

------------------------------------------------------------------------

## What This Workflow Does NOT Do

-   It does NOT automatically fix vulnerabilities
-   It does NOT update dependencies
-   It does NOT block merges unless configured to fail the build

Dependency updates are handled separately (e.g., via Dependabot).

------------------------------------------------------------------------

## Why This Matters

This workflow provides a security baseline by:

-   Detecting high-risk vulnerabilities early
-   Catching exposed credentials
-   Identifying insecure configurations
-   Generating SBOMs for compliance and auditing

It acts as an automated security guard on every pull request and
deployment.

------------------------------------------------------------------------

## How to Run Manually

1.  Go to **Actions**
2.  Select the Trivy workflow
3.  Click **Run workflow**

------------------------------------------------------------------------

## Severity Configuration

Current configuration scans for:

    HIGH,CRITICAL

You may adjust severity levels in:

    .github/workflows/trivy.yml

Be cautious when adding LOW or MEDIUM, as this may significantly
increase findings.

------------------------------------------------------------------------

## Permissions Used

The workflow uses:

    permissions:
      contents: read
      security-events: write

This allows it to: - Read repository contents - Upload findings to
GitHub Security

------------------------------------------------------------------------

# Summary

This Trivy workflow provides:

-   Repository vulnerability scanning
-   Secret detection
-   Configuration scanning
-   Docker image scanning
-   SBOM generation

All automatically through GitHub Actions.
