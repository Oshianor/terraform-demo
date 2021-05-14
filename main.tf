terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "demo-ec2-terraform-bucket"
    key = "terraform-state/state.tfstate"
    region = "af-south-1"

  }
}

provider "aws" {
  region = "af-south-1"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = var.vpc_cidr_block

  azs             = [var.avail_zone]
  public_subnets  = [var.subnet_cidr_block]

  vpc_tags = {
    Name = "${var.env_prefix}-vpc"
  }

  public_subnet_tags = {
    Name = "${var.env_prefix}-subnet-1"
  }

  tags = {
    Name : "${var.env_prefix}-tag"
  }
}


module "myapp-server" {
  source                = "./modules/webserver"
  image_name            = var.image_name
  avail_zone            = var.avail_zone
  env_prefix            = var.env_prefix
  my_ip                 = var.my_ip
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.public_subnets[0]
  instance_type         = var.instance_type
  my_pubic_key_location = var.my_pubic_key_location
}
