module "KHH-eks"{

  source = "terraform-aws-modules/eks/aws"
  version = "20.0.1"

  cluster_name    = var.cluster-name
  cluster_version = "1.28"  
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

 
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  authentication_mode="API_AND_CONFIG_MAP"
  
  enable_cluster_creator_admin_permissions = true
  access_entries = {
    # One access entry with a policy associated
    khh = {
      kubernetes_groups = []
      principal_arn     = aws_iam_user.khh.arn
      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        },
        example3 = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }

     root = {
      kubernetes_groups = []
      principal_arn     = var.root-arn
      policy_associations = {
        example1 = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        },
        example2 = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }



  enable_irsa = true
  vpc_id          = module.KHH-vpc.vpc_id
  subnet_ids      = module.KHH-vpc.private_subnets

  eks_managed_node_group_defaults = {
    instance_types = ["t3.small","t3.medium"]
    #iam_role_additional_policies={
    #  additional=aws_iam_role.Worker-role.arn
    #}
  }

  eks_managed_node_groups = {
    examples= {
      min_size     = 1
      max_size     = 1
      desired_size = 1
      instance_types = ["t3.medium","t3.small"]
      capacity_type  = "SPOT"
    }
  #  labels ={
  #    ondemand="true"
  #  }
  }
  
  # Terraform은 외부에있기 때문에 Vpc 안에잇는 클러스터에 접근하려면 ingress권한필요
   cluster_security_group_additional_rules = {
    ingress = {
      description                = "EKS Cluster allows 443 port to get API call"
      type                       = "ingress"
      from_port                  = 443
      to_port                    = 443
      protocol                   = "TCP"
      cidr_blocks                = ["0.0.0.0/0"] 
      source_node_security_group = false
    }
  }


}
