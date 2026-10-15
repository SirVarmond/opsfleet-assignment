resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "kube-system"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.15.0"

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      replicas = 1

      nodeSelector = {
        "karpenter.sh/controller" = "true"
      }

      dnsPolicy = "Default"

      settings = {
        clusterName       = module.eks.cluster_name
        clusterEndpoint   = module.eks.cluster_endpoint
        interruptionQueue = module.karpenter.queue_name
      }

      controller = {
        resources = {
          requests = {
            cpu    = "250m"
            memory = "256Mi"
          }
          limits = {
            memory = "1Gi"
          }
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    module.karpenter
  ]
}
