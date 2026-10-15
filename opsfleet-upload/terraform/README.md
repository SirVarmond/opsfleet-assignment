# Opsfleet — EKS & Karpenter POC

## Overview

A reproducible AWS Kubernetes infrastructure built with
Terraform, Amazon EKS and Karpenter.

Supports:
- Kubernetes 1.37 on Amazon EKS
- Automatic EC2 node provisioning with Karpenter
- AMD64 (Intel/AMD) and ARM64 (AWS Graviton)
- Spot and On-Demand instances
- Workload-based node scaling and consolidation

## Architecture

- Dedicated VPC across two Availability Zones
- Two public and two private subnets
- Single NAT Gateway for outbound private network access
- EKS with a managed bootstrap node group (t3.medium)
- Karpenter controller installed through Helm
- Separate AMD64 and ARM64 NodePools
- EC2NodeClass using Amazon Linux 2023
- EKS Pod Identity for Karpenter AWS permissions
- SQS/EventBridge for Spot interruption handling

Worker nodes run in private subnets.

## Prerequisites

- AWS account with sufficient permissions
- Terraform >= 1.6
- AWS CLI v2
- kubectl
- Helm v3

This configuration uses us-east-1 by default.

IMPORTANT: AWS resources incur charges while running.

## AWS Spot prerequisite

In a new AWS account, create the EC2 Spot service-linked
role if it does not already exist:

    aws iam get-role \
      --role-name AWSServiceRoleForEC2Spot

If the role does not exist:

    aws iam create-service-linked-role \
      --aws-service-name spot.amazonaws.com \
      --region us-east-1

This is an account-level prerequisite.

## Deployment

From the terraform/ directory:

    export AWS_PROFILE=opsfleet
    export AWS_REGION=us-east-1

Use an AWS CLI profile with the required IAM permissions.

Restrict EKS API access to your current public IP:

    MY_IP=$(curl -4 -fsS https://checkip.amazonaws.com)
    export TF_VAR_api_access_cidrs="[\"${MY_IP}/32\"]"

Initialize and validate:

    terraform init
    terraform fmt -check
    terraform validate

Deploy the AWS infrastructure first:

    terraform apply \
      -target=module.vpc \
      -target=module.eks \
      -target=module.karpenter

Configure Kubernetes access:

    aws eks update-kubeconfig \
      --region us-east-1 \
      --name opsfleet-eks

Verify bootstrap node:

    kubectl get nodes

Install Karpenter and NodePools:

    terraform apply

Verify:

    kubectl get pods -n kube-system
    kubectl get nodepools
    kubectl get ec2nodeclasses

## Workload examples

Deploy an AMD64 application:

    kubectl apply -f examples/amd64.yaml

Deploy an ARM64 / Graviton application:

    kubectl apply -f examples/arm64.yaml

Deploy an application requiring Spot capacity:

    kubectl apply -f examples/spot.yaml

Verify workload placement:

    kubectl get pods -o wide

    kubectl get nodes \
      -L kubernetes.io/arch,karpenter.sh/nodepool,karpenter.sh/capacity-type

    kubectl get nodeclaims -o wide

Karpenter provisions suitable EC2 instances automatically
when no existing node can accommodate the workload.

Spot capacity is interruptible and availability is not guaranteed.

## Cleanup

Delete example workloads:

    kubectl delete -f examples/ --ignore-not-found=true

Delete Karpenter-managed nodes:

    kubectl delete nodeclaims --all --wait=true

Destroy infrastructure:

    terraform destroy

Verify Terraform has no managed resources remaining:

    terraform state list

Also verify AWS resources have been removed.

The account-level EC2 Spot service-linked role may remain.

## Design decisions and limitations

- A single NAT Gateway reduces POC costs but is not highly available.
- One bootstrap node keeps baseline compute costs low.
- Karpenter runs with one replica for this POC.
- Instance selection supports both Spot and On-Demand.
- Karpenter manages application capacity independently
  of the bootstrap managed node group.
- Terraform state is local; production should use secured
  remote state with locking.
- EKS API public access is restricted by caller-provided CIDRs.
- The AL2023 AMI uses the latest alias for this POC;
  production deployments should pin a tested version.
- Production would require stronger HA, monitoring,
  backup, security and operational controls.

## Validation

Tested successfully on AWS us-east-1:

- EKS Kubernetes 1.37
- Karpenter 1.15.0
- AMD64 On-Demand: t3a.small
- ARM64 On-Demand: t4g.small
- AMD64 Spot: t3.small
- ARM64 Spot: t4g.small
- Kubernetes deployments successfully scheduled and running
- Infrastructure destruction through Terraform
