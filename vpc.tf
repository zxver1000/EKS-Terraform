module "KHH-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = ["ap-northeast-2a","ap-northeast-2c"]
  public_subnets = [for index in range(2):
  cidrsubnet("192.168.0.0/16",8,index)]
  private_subnets = [for index in range(2):
                      cidrsubnet(var.vpc_cidr, 8, index + 2)]
#  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  #One Natgateway setting
  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az= false

  
  enable_vpn_gateway = true
  


  ## ELB 서브넷 허용
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "karpenter.sh/discovery"=  var.cluster-name
  }

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
