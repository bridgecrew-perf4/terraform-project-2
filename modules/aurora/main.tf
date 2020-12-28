variable "stack_name" {}

variable "subnet_ids" {
  type = list(any)
}

variable "vpc_id" {}

data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

locals {
  nb_azs = length(data.aws_availability_zones.available.names)
}

resource "random_string" "rds_master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_string" "final_snapshot_id" {
  length  = 24
  special = false
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora_db_subnet_group_${var.stack_name}_${terraform.workspace}"
  subnet_ids = var.subnet_ids

  tags = {
    Name      = var.stack_name
    Terraform = true
  }
}

resource "aws_security_group" "db_security_group" {
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  tags = {
    Name      = var.stack_name
    Terraform = true
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = "keyedin-aurora-cluster"
  engine             = "aurora-mysql"
  database_name      = "${var.stack_name}_db"
  master_username    = "aurora"
  # master_password              = random_string.rds_master_password.result
  master_password              = "keyedin-default-password"
  backup_retention_period      = 14
  preferred_backup_window      = "01:00-03:00"
  preferred_maintenance_window = "sun:04:00-sun:06:00"
  db_subnet_group_name         = aws_db_subnet_group.aurora_subnet_group.name
  final_snapshot_identifier    = "${var.stack_name}-snapshot-${random_string.final_snapshot_id.result}"
  availability_zones           = data.aws_availability_zones.available.names

  deletion_protection = true

  vpc_security_group_ids = [
    aws_security_group.db_security_group.id
  ]

  tags = {
    Name      = var.stack_name
    Terraform = true
  }
}

resource "aws_rds_cluster_instance" "aurora_cluster_instance" {
  identifier           = "${var.stack_name}-cluster-instnace"
  cluster_identifier   = aws_rds_cluster.aurora_cluster.id
  instance_class       = "db.t2.small"
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  publicly_accessible  = false
  engine               = aws_rds_cluster.aurora_cluster.engine
  availability_zone    = data.aws_availability_zones.available.names[0]

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name      = var.stack_name
    Terraform = true
  }
}