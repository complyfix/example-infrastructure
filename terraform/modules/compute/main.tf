# Compute Module — EKS Cluster, Lambda Functions, ECR
#
# VIOLATIONS IN THIS FILE:
# - EKS public endpoint enabled (CKV_AWS_39)
# - EKS no audit logging (CKV_AWS_37)
# - Lambda no VPC (CKV_AWS_117)
# - ECR scan disabled (CKV_AWS_163)

# ──────────────────────────────────────────────
# EKS Cluster
# ──────────────────────────────────────────────

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

# VIOLATION: Public endpoint enabled (CKV_AWS_39)
# VIOLATION: No audit logging (CKV_AWS_37)
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}"
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = var.private_subnet_ids

    # VIOLATION: Public endpoint should be false (CKV_AWS_39)
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  # VIOLATION: No audit logging enabled (CKV_AWS_37)
  # enabled_cluster_log_types = ["audit", "api", "authenticator"]
  # (Commented out — violation)

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-eks"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]
}

# ──────────────────────────────────────────────
# EKS Node Group
# ──────────────────────────────────────────────

resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = 2
    max_size     = 6
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    environment = var.environment
    role        = "worker"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nodes"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr_read,
  ]
}

# ──────────────────────────────────────────────
# ECR Repository
# ──────────────────────────────────────────────

# VIOLATION: Image scanning disabled (CKV_AWS_163)
resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}/api-service"
  image_tag_mutability = "IMMUTABLE"

  # VIOLATION: No scan on push
  # image_scanning_configuration {
  #   scan_on_push = true
  # }

  tags = merge(var.tags, {
    Name = "${var.project_name}-api-ecr"
  })
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 20 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ──────────────────────────────────────────────
# Lambda — Event Processor
# ──────────────────────────────────────────────

resource "aws_iam_role" "lambda_processor" {
  name = "${var.project_name}-${var.environment}-lambda-processor"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_processor.name
}

# VIOLATION: Lambda not in VPC (CKV_AWS_117)
resource "aws_lambda_function" "event_processor" {
  function_name = "${var.project_name}-${var.environment}-event-processor"
  role          = aws_iam_role.lambda_processor.arn
  handler       = "main.handler"
  runtime       = "python3.12"
  timeout       = 300
  memory_size   = 512

  filename = "lambda/event-processor.zip"

  # VIOLATION: No VPC config
  # vpc_config {
  #   subnet_ids         = var.private_subnet_ids
  #   security_group_ids = [aws_security_group.lambda.id]
  # }

  environment {
    variables = {
      ENVIRONMENT = var.environment
      DB_HOST     = "placeholder"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-event-processor"
  })
}
