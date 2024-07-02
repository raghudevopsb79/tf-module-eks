locals {
  tags     = merge(var.tags, { module_name = "tf-module-eks" })
  eks_tags = merge(local.tags, { Name = "${var.env}-eks" })
}

