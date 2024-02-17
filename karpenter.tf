###
### The data source should cause a call to api.ecr-public.us-east-1.amazonaws.com as "ECR-public actions are only supported in the us-east-1 region"
###

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}


provider "kubectl" {
  
 # config_path = "~/.kube/KHH-Cluster"
  
  apply_retry_count      = 5
  host                   = module.KHH-eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.KHH-eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.KHH-eks.cluster_name]
  }
}


module "karpenter" {
 
  source       = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.2.1"
  cluster_name = module.KHH-eks.cluster_name
 create_node_iam_role = false
  irsa_oidc_provider_arn       = module.KHH-eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
  enable_irsa=true
  create_access_entry = false
  
  ### Manged Group example Node Group에 Karpenter pod 생성

  node_iam_role_arn    = module.KHH-eks.eks_managed_node_groups["karpenter"].iam_role_arn
  # node_iam_role_additional_policies = {
  #   AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  # }

}

resource "helm_release" "karpenter" {
  depends_on = [
  module.KHH-eks,
  module.karpenter
  ]
  namespace        = "karpenter"
  create_namespace = true
  name                = "karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  repository      = "oci://public.ecr.aws/karpenter"
  version         = "v0.34.0"
  
  values = [
    <<-EOT
    settings:
      clusterName: ${module.KHH-eks.cluster_name}
      clusterEndpoint: ${module.KHH-eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    EOT
  ]
 
}

###
### NODE_ POOL

### CLuster join이 안되네 왜지????? Networking 문젠가.. ㅅㅂ ㅠㅠ

resource "kubectl_manifest" "karpenter_provisioner" {
 
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            apiVersion: karpenter.k8s.aws/v1beta1
            kind: EC2NodeClass
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["t"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: Gt
              values: ["1"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["spot", "on-demand"]            
            - key: "topology.kubernetes.io/zone"
              operator: In
              values: ["ap-northeast-2a", "ap-northeast-2b","ap-northeast-2c"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["arm64"]
      
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
 
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      role: ${module.KHH-eks.eks_managed_node_groups["karpenter"].iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.KHH-eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.KHH-eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.KHH-eks.cluster_name}

  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

#output "kar"{
#  value= module.KHH-eks.eks_managed_node_groups["examples"]
#}
#output "set"{
#  value= module.karpenter.node_iam_role_name
#  }
#output "endpoint"{
#  value=module.KHH-eks.cluster_endpoint
#}

## ${module.karpenter.node_iam_role_name}

#${module.KHH-eks.eks_managed_node_groups["examples"].iam_role_name}
