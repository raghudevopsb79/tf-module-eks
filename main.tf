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

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  configuration_values = jsonencode({
    "enableNetworkPolicy" : "true"
  })
}

resource "aws_eks_node_group" "node-groups" {
  depends_on = [aws_eks_addon.vpc-cni]

  for_each        = var.node_groups
  instance_types  = each.value["instance_types"]
  capacity_type   = each.value["capacity_type"]
  node_group_name = each.name
  scaling_config {
    desired_size = each.value["node_min_size"]
    max_size     = each.value["node_max_size"]
    min_size     = each.value["node_min_size"]
  }

  cluster_name  = aws_eks_cluster.main.name
  node_role_arn = aws_iam_role.node.arn
  subnet_ids    = var.subnet_ids
  tags          = local.eks_tags
}


