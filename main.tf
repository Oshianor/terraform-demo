provider "aws" {
  region = "af-south-1"
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "my_pubic_key_location" {}
variable "my_private_key_location" {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name : "${var.env_prefix}-igw"
  }
}



resource "aws_default_route_table" "main_rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name : "${var.env_prefix}-main-rtb"
  }
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


output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}


resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.my_pubic_key_location)
}


resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
  availability_zone = var.avail_zone

  associate_public_ip_address = true

  key_name = aws_key_pair.ssh-key.key_name

  # user_data = file("entry-script.sh")


  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.my_private_key_location)
  }

  provisioner "file" {
    source = "entry-script.sh"
    destination = "/home/ec2-user/entry-script-local.sh"
  }

  provisioner "remote-exec" {
    script = file("entry-script-local.sh")
  }
  
  provisioner "local-exec" {
    command = "echo ${self.public_ip}"
  }

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
