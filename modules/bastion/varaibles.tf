# EBS backed HVM
variable "aws_linux_amis_ebs" {
  default = {
    ap-northeast-1 = "ami-29160d47"
    ap-northeast-2 = "ami-cf32faa1"
    ap-southeast-1 = "ami-1ddc0b7e"
    ap-southeast-2 = "ami-0c95b86f"
    eu-central-1   = "ami-d3c022bc"
    eu-west-1      = "ami-b0ac25c3"
    sa-east-1      = "ami-fb890097"
    us-east-1      = "ami-f5f41398"
    us-west-1      = "ami-6e84fa0e"
    us-west-2      = "ami-d0f506b0"
  }
}

# Instance backed HVM
variable "aws_linux_amis_instant" {
  default = {
    eu-west-2 = "ami-08b993f76f42c3e2f"
  }
}