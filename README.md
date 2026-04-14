# Example Infrastructure

> **Warning**
> This repository contains intentionally non-compliant infrastructure code for demo purposes. Do not use any patterns from this repo in production.

Sample Terraform + Helm infrastructure with intentional SOC 2 / HIPAA compliance violations. Used to demo and test [ComplyFix](https://complyfix.io).

## What's Inside

- **Terraform** — VPC, EKS, RDS, S3, IAM, CloudTrail, CloudWatch across 5 modules
- **Helm** — Kubernetes API service chart with default, staging, and production values

## Expected Scan Output

```
47 findings across 2 frameworks (SOC 2, HIPAA)
38 auto-fixable (17 deterministic, 21 template+config)
Traced across 3 Terraform modules + 1 Helm chart
```

## Try It

```bash
complyfix scan github.com/complyfix/example-infrastructure
```

## Structure

```
terraform/
  main.tf                   # Root module — calls all child modules
  variables.tf              # Input variables
  terraform.tfvars          # Default values (intentionally insecure)
  modules/
    networking/             # VPC, subnets, security groups, ALB
    storage/                # S3 buckets, EBS volumes
    database/               # RDS PostgreSQL, DynamoDB
    compute/                # EKS cluster, Lambda, ECR
    security/               # IAM, CloudTrail, CloudWatch, SNS
  environments/
    prod/                   # Production overrides

helm/
  api-service/              # Main API service Helm chart
    values.yaml             # Default values (missing security context, probes, limits)
    values.staging.yaml     # Staging overrides
    values.prod.yaml        # Production overrides (no network policy)
```

## Learn More

- [ComplyFix](https://complyfix.io) — IaC compliance remediation for SOC 2 / HIPAA
- [Install the CLI](https://complyfix.io) — `brew install complyfix/tap/complyfix`
