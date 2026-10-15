resource "helm_release" "karpenter_nodepools" {
  name      = "karpenter-nodepools"
  namespace = "kube-system"

  chart = "${path.module}/charts/karpenter-nodepools"

  wait    = true
  timeout = 300

  values = [
    yamlencode({
      clusterName = module.eks.cluster_name
      nodeRole    = module.karpenter.node_iam_role_name
    })
  ]

  depends_on = [
    helm_release.karpenter
  ]
}
