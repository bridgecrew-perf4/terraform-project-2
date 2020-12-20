variable "stack_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "public_ips" {
  type = map(any)
}


provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket  = "keyedin-private"
    key     = "infrastructure/terraform.tfstate"
    region  = "eu-west-2"
    profile = "keyedin"
  }
}

// VPC
module "vpc" {
  source        = "./modules/vpc"
  stack_name    = var.stack_name
}

// vm
module "ec2" {
  source             = "./modules/ec2"
  stack_name         = var.stack_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_id   = module.vpc.public_subnet_ids[0]
  public_ips         = var.public_ips
  public_bucket_arn  = module.s3.public_bucket_arn
  private_bucket_arn = module.s3.private_bucket_arn
}

module "s3" {
  source     = "./modules/s3"
  stack_name = var.stack_name
}

// database
module "aurora" {
  source     = "./modules/aurora"
  stack_name = var.stack_name
  subnet_ids = module.vpc.public_subnet_ids
  vpc_id     = module.vpc.vpc_id
}

module "codedeploy" {
  source     = "./modules/codedeploy"
  stack_name = var.stack_name
}

module "ecr" {
  source     = "./modules/ecr"
  stack_name = var.stack_name
}

module "elb" {
  source = "./modules/elb"
  stack_name = var.stack_name
  subnet_ids = module.vpc.public_subnet_ids
  ec2_instance_ids = [module.ec2.vm_id]
  security_groups = [
    module.vpc.vpc_sg,
    module.ec2.ec2_sg
  ]
}
