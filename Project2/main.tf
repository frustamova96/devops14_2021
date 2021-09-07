data "aws_ami" "project2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

#####################LOCAL-EC2############################

resource "aws_instance" "local-ec2" {
  ami           = data.aws_ami.project2.id
  instance_type = var.instance_type[0]
  key_name               = aws_key_pair.my-key.id
  vpc_security_group_ids = [aws_security_group.rm2-sg.id]
  

  provisioner "local-exec" {
    command = "echo ${aws_instance.local-ec2.public_ip} >> public_ips.txt"
  }

  tags = {
    "Name" = element(var.tags, 0)
  }
}

#######################REMOTE-EC2############################

resource "aws_key_pair" "my-key" {
  key_name   = "devops-tf-key"
  public_key = file("${path.module}/my_public_key.txt")
}

resource "aws_instance" "remote-ec2" {
  ami                    = data.aws_ami.project2.id
  instance_type          = var.instance_type[0]
  key_name               = aws_key_pair.my-key.id
  vpc_security_group_ids = [aws_security_group.rm2-sg.id]
   tags = {
    "Name" = element(var.tags, 1)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y httpd",
      "cd /var/www/html",
      "sudo wget https://devops14-mini-project.s3.amazonaws.com/default/index-default.html",
      "sudo wget https://devops14-mini-project.s3.amazonaws.com/default/mycar.jpeg",
      "sudo mv index-default.html index.html",
      "sudo systemctl enable httpd --now"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./private_key.pem")
      host        = self.public_ip
    }

  }
}

################SECURITY_GROUP###################

resource "aws_security_group" "rm2-sg" {
  name = "project2"

  ingress {
    from_port   = 22 
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80 
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#############VPC################

resource "aws_vpc" "project-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "terraform-vpc"
  }
}


resource "aws_internet_gateway" "project-ig" {
  vpc_id = aws_vpc.project-vpc.id
  tags = {
    "Name" = "project-ig"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.project-vpc.id
  cidr_block = "10.0.0.0/24"
  tags = {
    "Name" = "project-public-subnet"
  }
}

resource "aws_subnet" "my-private-subnet" {
  vpc_id     = aws_vpc.project-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    "Name" = "project-private-subnet"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.project-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project-ig.id
  }
  tags = {
    "Name" = "ig-public-rt"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.project-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.project-nat-gw.id
  }
  tags = {
    "Name" = "nat-private-rt"
  }
}

resource "aws_route_table_association" "public-association" {
 subnet_id = aws_subnet.public-subnet.id
 route_table_id = aws_route_table.public-rt.id
}
 
resource "aws_route_table_association" "private-association" {
 subnet_id = aws_subnet.my-private-subnet.id
 route_table_id = aws_route_table.private-rt.id
}

#######################EIP####################

resource "aws_eip" "project-eip" {
  vpc = true
  tags = {
    "Name" = "project-eip"
  }
}

# resource "aws_eip_association" "project-eip" {
#   instance_id   = aws_instance.remote-ec2.id
#   allocation_id = aws_eip.project-eip.id
# }

resource "aws_eip" "project-eip2" {
  vpc = true
  tags = {
    "Name" = "project-eip2"
  }
}

resource "aws_eip_association" "project-eip2" {
  instance_id   = aws_instance.local-ec2.id
  allocation_id = aws_eip.project-eip2.id
}

#####################NAT#################


resource "aws_nat_gateway" "project-nat-gw" {
  allocation_id = aws_eip.project-eip.id
  subnet_id     = aws_subnet.my-private-subnet.id
  tags = {
    "Name" = "project-nat-gw"
  }
}

###################VARIABLES##############

variable "tags" {
  type    = list(any)
  default = ["local-exec", "remote-exec", ]
}

variable "instance_type" {
  type    = list(any)
  default = ["t2.micro", "t2.large", "t2.small"]
}


#############TIMEFORMAT############

locals {
  time = formatdate("DD MM YYYY hh:mm: ZZZ", timestamp())
}

output "timestamp" {
  value = local.time
}