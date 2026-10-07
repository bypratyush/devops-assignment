# Workflows

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

GitHub Actions only runs workflow files from `.github/workflows/` at the
**repository root**, so a workflow placed here would never trigger. The pipeline
for this project is:

**[/.github/workflows/final-project.yml](../../../.github/workflows/final-project.yml)**

It runs on pushes and pull requests to `main` that touch `final-devops-project/**`
(or the workflow file itself), plus manual `workflow_dispatch`:

```text
backend-test, frontend-build -> sast, sca, secret-scan
                             -> docker-build -> image-scan
all of the above             -> security-gate -> push (main) -> deploy-gitops (main)
```

See the CI/CD and DevSecOps sections of the [project README](../../README.md#cicd-pipeline)
and [security/README.md](../../security/README.md) for what each job does and the
captured run.
