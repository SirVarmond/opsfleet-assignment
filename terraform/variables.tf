variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "opsfleet-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.37"
}

variable "api_access_cidrs" {
  description = "Allowed public IP ranges for EKS API access"
  type        = list(string)
}
