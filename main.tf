provider "aws" {
  region = "af-south-1"
}


resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}


module "myapp-subnet" {
  source                 = "./modules/subnet"
  subnet_cidr_block      = var.subnet_cidr_block
  env_prefix             = var.env_prefix
  avail_zone             = var.avail_zone
  vpc_id                 = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}


module "myapp-server" {
  source                = "./modules/webserver"
  image_name            = var.image_name
  avail_zone            = var.avail_zone
  env_prefix            = var.env_prefix
  my_ip                 = var.my_ip
  vpc_id                = aws_vpc.myapp-vpc.id
  subnet_id             = module.myapp-subnet.subnet.id
  instance_type         = var.instance_type
  my_pubic_key_location = var.my_pubic_key_location
}
