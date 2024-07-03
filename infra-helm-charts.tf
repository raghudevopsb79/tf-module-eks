resource "null_resource" "get-kubeconfig" {

  depends_on = [aws_eks_node_group.node-groups, aws_eks_cluster.main]

  provisioner "local-exec" {
    command =<<EOF
aws eks update-kubeconfig --name "${var.env}-eks"
EOF
  }

}

data "http" "metric-server" {
  url = "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
}

resource "kubectl_manifest" "metric-server" {
  depends_on = [null_resource.get-kubeconfig]
  yaml_body = data.http.metric-server.body
}

resource "kubectl_manifest" "cluster-autoscaler" {
  depends_on = [null_resource.get-kubeconfig]
  yaml_body = templatefile("${path.module}/cluster-autoscale.yaml", {
    IAM_ROLE = ""
    CLUSTER_NAME = ""
  })
}

