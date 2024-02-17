data "aws_eks_cluster_auth" "default" {
  name = module.KHH-eks.cluster_name
}

module "lb_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "KHH_eks_lb"
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.KHH-eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}
##
## k8s install0
##
provider "kubernetes" {
  host                   = module.KHH-eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.KHH-eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.default.token
  

}

##
##  helm install
##

provider "helm" {
  kubernetes {
    host                   = module.KHH-eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.KHH-eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.default.token
   config_path = "~/.kube/KHH-Cluster"
  }

}



resource "kubernetes_service_account" "service-account" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
        "app.kubernetes.io/name"= "aws-load-balancer-controller"
        "app.kubernetes.io/component"= "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "lb" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    module.KHH-eks,
    kubernetes_service_account.service-account
  ]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.KHH-vpc.vpc_id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = module.KHH-eks.cluster_name
  }
}

