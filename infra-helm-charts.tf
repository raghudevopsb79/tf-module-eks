resource "null_resource" "get-kubeconfig" {

  depends_on = [aws_eks_node_group.node-groups, aws_eks_cluster.main]

  provisioner "local-exec" {
    command = <<EOF
aws eks update-kubeconfig --name "${var.env}-eks"
EOF
  }

}

data "http" "metric-server" {
  url = "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
}

data "kubectl_file_documents" "metric-server" {
  content = data.http.metric-server.body
}

resource "kubectl_manifest" "metric-server" {
  depends_on = [null_resource.get-kubeconfig]

  count     = length(data.kubectl_file_documents.metric-server.documents)
  yaml_body = data.kubectl_file_documents.metric-server.documents[count.index]
}

## Cluster Autoscaler

resource "local_file" "cluster-autoscaler" {
  content  = templatefile("${path.module}/cluster-autoscale.yaml", {
    IAM_ROLE     = aws_iam_role.eks-cluster-autoscaler.arn
    CLUSTER_NAME = aws_eks_cluster.main.name
  })
  filename = "${path.module}/cluster-autoscale-local.yaml"
}

data "kubectl_file_documents" "cluster-autoscaler" {
  depends_on = [aws_eks_cluster.main, local_file.cluster-autoscaler]
  content = file("${path.module}/cluster-autoscale-local.yaml")
}

resource "kubectl_manifest" "cluster-autoscaler" {
  depends_on = [null_resource.get-kubeconfig, aws_eks_cluster.main]

  count     = length(data.kubectl_file_documents.cluster-autoscaler.documents)
  yaml_body = data.kubectl_file_documents.cluster-autoscaler.documents[count.index]
}

# Argocd

resource "kubectl_manifest" "argocd-namespace" {
  depends_on = [null_resource.get-kubeconfig, aws_eks_cluster.main]

  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
YAML
}

data "kubectl_file_documents" "argocd" {
  content = file("${path.module}/argo.yaml")
}

resource "kubectl_manifest" "argocd" {
  depends_on = [null_resource.get-kubeconfig, kubectl_manifest.argocd-namespace, aws_eks_cluster.main]

  count              = length(data.kubectl_file_documents.argocd.documents)
  yaml_body          = data.kubectl_file_documents.argocd.documents[count.index]
  override_namespace = "argocd"
}
