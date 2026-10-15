module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.26.0"

  cluster_name = module.eks.cluster_name

  # IAM role used by Karpenter-created EC2 nodes
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = var.cluster_name

  # Allow Karpenter controller to access AWS
  create_pod_identity_association = true

  # Enable Spot interruption handling
  enable_spot_termination = true

  tags = {
    Environment = "poc"
  }
}
