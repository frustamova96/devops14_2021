resource "aws_key_pair" "my-key" {
  key_name   = "devops14_2021"
  public_key = file("${path.module}/public_key.txt")
}

resource "aws_eip" "my_eip" {
  vpc = true
  tags = {
    Name  = "devops14_2021"
    Owner = "Feruza"
  }
}

resource "aws_security_group" "dynamic-sg" {
  name = "devops14_2021"
  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "egress" {
    for_each = var.egress_ports
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_instance" "project-ec2" {
  ami           = lookup(var.ami, var.region)
  instance_type = var.instance_type[0]
  key_name      = aws_key_pair.my-key.key_name
  tags = {
      "Name" = "devops14_2021"
  }
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.dynamic-sg.id
  network_interface_id = aws_instance.project-ec2.primary_network_interface_id
}

output "eip" {
  value = aws_eip.my_eip.public_ip
}