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

data "kubectl_file_documents" "cluster-autoscaler" {
  content = templatefile("${path.module}/cluster-autoscale.yaml", {
    IAM_ROLE     = aws_iam_role.eks-cluster-autoscaler.arn
    CLUSTER_NAME = aws_eks_cluster.main.name
  })
}

resource "kubectl_manifest" "cluster-autoscaler" {
  depends_on = [null_resource.get-kubeconfig]

  count     = length(data.kubectl_file_documents.cluster-autoscaler.documents)
  yaml_body = data.kubectl_file_documents.cluster-autoscaler.documents[count.index]
}

# Argocd

resource "kubectl_manifest" "argocd-namespace" {
  depends_on = [null_resource.get-kubeconfig]

  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
YAML
}

data "http" "argocd" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
}

data "kubectl_file_documents" "argocd" {
  content = data.http.argocd.body
}

# resource "kubectl_manifest" "argocd" {
#   depends_on = [null_resource.get-kubeconfig, kubectl_manifest.argocd-namespace]
#
#   count     = length(data.kubectl_file_documents.argocd.documents)
#   yaml_body = data.kubectl_file_documents.argocd.documents[count.index]
# }
