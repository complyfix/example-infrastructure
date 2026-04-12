# Acme Platform — Infrastructure

Production infrastructure for the Acme SaaS Platform. Manages AWS resources via Terraform and Kubernetes workloads via Helm.

## Architecture

- **VPC** with public/private subnets across 3 AZs
- **EKS** cluster (v1.29) running API and worker services
- **RDS** PostgreSQL 16 (primary + read replica)
- **DynamoDB** for session management
- **S3** buckets for app data, user uploads, logs, backups
- **Lambda** for async event processing
- **ALB** for ingress traffic

## Structure

```
terraform/
  main.tf                   # Root module — calls all child modules
  variables.tf              # Input variables
  terraform.tfvars          # Default values
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
    values.yaml             # Default values
    values.staging.yaml     # Staging overrides
    values.prod.yaml        # Production overrides
```

## Deployment

```bash
# Terraform
cd terraform
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply

# Helm
helm upgrade --install api-service ./helm/api-service \
  --values helm/api-service/values.yaml \
  --values helm/api-service/values.prod.yaml \
  --namespace acme --create-namespace
```

## Team

Platform Engineering — 3 engineers
Last audit: None (preparing for first SOC 2)
