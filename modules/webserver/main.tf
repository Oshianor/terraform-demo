resource "aws_default_security_group" "default-sg" {
#   name   = "myapp-sg"
  vpc_id = var.vpc_id

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
    values = [ var.image_name ]
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
  
  subnet_id = var.subnet_id
  vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
  availability_zone = var.avail_zone

  associate_public_ip_address = true

  key_name = aws_key_pair.ssh-key.key_name

  user_data = file("entry-script.sh")

  tags = {
    Name : "${var.env_prefix}-server"
  }
}
