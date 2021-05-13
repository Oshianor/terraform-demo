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
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  env_prefix = var.env_prefix
  avail_zone = var.avail_zone
  vpc_id = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}


resource "aws_default_security_group" "default-sg" {
#   name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    cidr_blocks = [var.my_ip]
    description = "SSH SG"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "All trafic allowed"
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
  }

  egress {
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Outgoing network access"
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    prefix_list_ids = []
  }

  tags = {
    Name : "${var.env_prefix}-default-sg"
  }

}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-x86_64-gp2" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
}



resource "aws_key_pair" "ssh-key" {
  key_name = "server-key1"
  public_key = file(var.my_pubic_key_location)
}


resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  
  subnet_id = module.myapp-subnet.subnet.id
  vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
  availability_zone = var.avail_zone

  associate_public_ip_address = true

  key_name = aws_key_pair.ssh-key.key_name

  user_data = file("entry-script.sh")

  tags = {
    Name : "${var.env_prefix}-server"
  }
}

























# output "aws_ami_id" {
#   value = data.aws_ami.latest-amazon-linux-image.id
# }


# resource "aws_route_table" "myapp-route-table" {
#   vpc_id = aws_vpc.myapp-vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp-igw.id
#   }
#   tags = {
#     Name : "${var.env_prefix}-route-table"
#   }
# }

# resource "aws_route_table_association" "myapp-rtb-subnet" {
#   subnet_id      = aws_subnet.myapp-subnet-1.id
#   route_table_id = aws_route_table.myapp-route-table.id
# }

# resource "aws_security_group" "myapp-sg" {
#   name   = "myapp-sg"
#   vpc_id = aws_vpc.myapp-vpc.id

#   ingress {
#     cidr_blocks = [var.my_ip]
#     description = "SSH SG"
#     from_port   = 22
#     protocol    = "tcp"
#     to_port     = 22
#   }

#   ingress {
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "All trafic allowed"
#     from_port   = 8080
#     protocol    = "tcp"
#     to_port     = 8080
#   }

#   egress {
#     cidr_blocks     = ["0.0.0.0/0"]
#     description     = "Outgoing network access"
#     from_port       = 0
#     protocol        = "-1"
#     to_port         = 0
#     prefix_list_ids = []
#   }

#   tags = {
#     Name : "${var.env_prefix}-sg"
#   }

# }
