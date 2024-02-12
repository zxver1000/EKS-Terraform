#output "vpc-id"{
#  value="${module.KHH_VPC.vpc-id}"
#}


output "vpc-id"{
  value=module.KHH-vpc.vpc_id
}
