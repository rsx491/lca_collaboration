# Trivy Workflow Deep-Dive (Line-by-Line Context)

This document explains the **`trivy.yml`** GitHub Actions workflow used in this repository, focusing on **what each section/line does** and why it exists.

> **Workflow name in repo:** `POC - Trivy (fs + config + secrets + image + SBOM)`  
> **Typical location:** `.github/workflows/trivy.yml`

---

## Full workflow (annotated)


```yaml
name: POC - Trivy (fs + config + secrets + image + SBOM)
# name: The display name shown in GitHub Actions for this workflow.

on: 
  pull_request:
  push:
    branches: [ main ]
  workflow_dispatch:
# on: Defines the events that trigger this workflow.
# - pull_request: Run on PRs targeting the default branch (and/or branches configured by repo settings).
# - push.branches: Run when commits are pushed to the main branch.
# - workflow_dispatch: Allow a human to click "Run workflow" in the Actions UI.

permissions:
  contents: read
  security-events: write
# permissions: Sets the default GitHub token (GITHUB_TOKEN) permissions for all jobs.
# - contents: read -> Allows actions to checkout/read repo code.
# - security-events: write -> Allows uploading SARIF to GitHub Code Scanning (Security tab).

jobs:
  repo_scan:
    name: Repo scan (vuln + secrets + config)
    runs-on: ubuntu-latest
    # repo_scan job: Scans the repository filesystem (source + configs) using Trivy.
    steps:
      - uses: actions/checkout@v4
        # Checks out the repository code so Trivy can scan the working directory.

      - name: Cache Trivy DB
        uses: actions/cache@v4
        with:
          path: ~/.cache/trivy
          key: ${{ runner.os }}-trivy-${{ github.run_id }}
          restore-keys: |
            ${{ runner.os }}-trivy-
        # Caches Trivy's vulnerability database and related cache under ~/.cache/trivy.
        # restore-keys: allows fallback to older cache keys if exact key doesn't exist.
        #
        # NOTE: Using github.run_id makes the cache key unique per run (less reuse).
        # For better cache reuse, a stable key is often used (see "Suggested improvements" below).

      - name: Trivy FS + Config scan (SARIF)
        uses: aquasecurity/trivy-action@0.28.0
        with:
          scan-type: fs
          scan-ref: .
          scanners: vuln,secret,config
          format: sarif
          output: trivy-fs.sarif
          severity: HIGH,CRITICAL
          ignore-unfixed: true
        # Runs Trivy in filesystem (fs) mode:
        # - scan-ref: . -> scan the repository checkout directory
        # - scanners: vuln,secret,config -> enable vulnerability scanning, secret scanning, and config scanning
        # - format: sarif -> output results in SARIF for GitHub Code Scanning
        # - output: trivy-fs.sarif -> writes results to this file
        # - severity: HIGH,CRITICAL -> only report HIGH and CRITICAL findings
        # - ignore-unfixed: true -> suppress vulnerabilities with no fix available (reduces noise)

      - name: Upload SARIF to GitHub Code Scanning
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-fs.sarif
        # Uploads the SARIF output to GitHub's Code Scanning UI
        # (Security → Code scanning alerts).

      - name: Upload repo scan artifact
        uses: actions/upload-artifact@v4
        with:
          name: trivy-fs
          path: trivy-fs.sarif
        # Uploads the SARIF file as a downloadable workflow artifact
        # (Actions → workflow run → Artifacts).

  sbom:
    name: Generate SBOM
    runs-on: ubuntu-latest
    # sbom job: Creates a CycloneDX SBOM for the repository filesystem.
    steps:
      - uses: actions/checkout@v4
        # Checks out code for SBOM generation.

      - name: Cache Trivy DB
        uses: actions/cache@v4
        with:
          path: ~/.cache/trivy
          key: ${{ runner.os }}-trivy-${{ github.run_id }}
          restore-keys: |
            ${{ runner.os }}-trivy-
        # Same Trivy DB cache behavior as repo_scan.

      - name: Generate SBOM (CycloneDX)
        uses: aquasecurity/trivy-action@0.28.0
        with:
          scan-type: fs
          scan-ref: .
          format: cyclonedx
          output: sbom.cdx.json
        # Generates an SBOM from the filesystem:
        # - format: cyclonedx -> CycloneDX SBOM output format
        # - output: sbom.cdx.json -> SBOM file name

      - name: Upload SBOM artifact
        uses: actions/upload-artifact@v4
        with:
          name: sbom-cyclonedx
          path: sbom.cdx.json
        # Uploads the SBOM file as an artifact.

  image_scan:
    name: Build + scan Docker image
    runs-on: ubuntu-latest
    # image_scan job: Builds the Docker image and scans the resulting container image.
    steps:
      - uses: actions/checkout@v4
        # Checks out repo so Docker build context is available.

      - name: Cache Trivy DB
        uses: actions/cache@v4
        with:
          path: ~/.cache/trivy
          key: ${{ runner.os }}-trivy-${{ github.run_id }}
          restore-keys: |
            ${{ runner.os }}-trivy-
        # Same Trivy DB cache behavior as other jobs.

      - name: Build Docker image
        run: docker build --build-arg CI=true -t lca-collaboration:poc .
        # Builds the Docker image using the Dockerfile in the repo root.
        # - --build-arg CI=true -> passes CI=true build arg (only meaningful if Dockerfile uses ARG CI)
        # - -t lca-collaboration:poc -> tags the image locally so Trivy can scan it
        # - . -> uses current directory as Docker build context

      - name: Trivy image scan (SARIF)
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: lca-collaboration:poc
          format: sarif
          output: trivy-image.sarif
          severity: HIGH,CRITICAL
          ignore-unfixed: true
        # Runs Trivy in image mode:
        # - image-ref: lca-collaboration:poc -> scan the locally built image tag
        # - format/output: SARIF -> uploadable to GitHub Code Scanning
        # - severity: HIGH,CRITICAL -> only high-impact findings
        # - ignore-unfixed: true -> reduce noise for unfixed CVEs

      - name: Upload SARIF to GitHub Code Scanning
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-image.sarif
        # Uploads image scan findings to GitHub Code Scanning.

      - name: Upload image scan artifact
        uses: actions/upload-artifact@v4
        with:
          name: trivy-image
          path: trivy-image.sarif
        # Uploads the image SARIF as an artifact.
```

---

## How the three jobs fit together

- **`repo_scan`**: Scans the repo’s files directly (source, configs, IaC) for:
  - vulnerabilities, secrets, misconfigurations  
  Produces `trivy-fs.sarif` (Code Scanning + artifact).

- **`sbom`**: Generates an SBOM from the repository contents.  
  Produces `sbom.cdx.json` (artifact).

- **`image_scan`**: Builds your Docker image then scans the final image layers.  
  Produces `trivy-image.sarif` (Code Scanning + artifact).

This gives you coverage at three levels:
1) source/configs, 2) inventory (SBOM), 3) runtime artifact (container image).

---

## Suggested improvements (optional)

These are optional “cleanup” items you might consider after the POC:

### 1) Improve cache reuse
Your current cache key includes `github.run_id`, which changes every run, reducing reuse.

A more reusable pattern:

```yaml
key: ${{ runner.os }}-trivy-db
restore-keys: |
  ${{ runner.os }}-trivy-
```

### 2) Decide whether findings should fail the build
Right now, the workflow **reports** findings, but may not fail PRs unless Trivy’s default behavior or action settings cause a failure.

If you want to *block merges* on findings, add:

```yaml
exit-code: 1
```

And optionally set `severity` to the level you want to enforce.

### 3) Avoid duplicate uploads if desired
You upload SARIF for both filesystem and image scans. That’s okay (GitHub can show both), but you may want to keep naming consistent in the Code Scanning UI or add categories.

### 4) Pin action versions intentionally
You pinned `aquasecurity/trivy-action@0.28.0`, which is good for reproducibility. Periodically update it (Dependabot can help).

---

## Where to view output

- **Security → Code scanning alerts**  
  Shows SARIF results uploaded from `repo_scan` and `image_scan`.

- **Actions → Workflow run → Artifacts**  
  Download:
  - `trivy-fs.sarif` (repo scan findings)
  - `trivy-image.sarif` (image scan findings)
  - `sbom.cdx.json` (CycloneDX SBOM)

---

## FAQ

### Why do we scan both filesystem and image?
Filesystem scanning catches issues in source + IaC/configs before build. Image scanning catches what ends up shipping, including OS packages and final dependency resolution.

### Why SARIF?
SARIF is the format GitHub Code Scanning understands, so findings show up under Security → Code scanning alerts.

### What is an SBOM?
A Software Bill of Materials lists components/dependencies found in the project, helping with compliance and incident response.

