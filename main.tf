resource "aws_eks_cluster" "main" {
  name                      = "${var.env}-eks"
  tags                      = local.eks_tags
  role_arn                  = aws_iam_role.cluster.arn
  enabled_cluster_log_types = ["audit"]
  version                   = var.eks_version

  vpc_config {
    subnet_ids = var.subnet_ids
  }
}

