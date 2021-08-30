variable "ingress_ports" {
  type    = list(any)
  default = [22, 80, 443]
}

variable "egress_ports" {
  type    = list(any)
  default = [8000, 8080, 8888]
}

variable "ami" {
  type = map(any)
  default = {
    us-east-2 = "ami-0443305dabd4be2bc"
    us-east-1 = "ami-0c2b8ca1dad447f8a"
    us-west-1 = "ami-04b6c97b14c54de18"
    us-west-2 = "ami-083ac7c7ecf9bb9b0"
  }
}

variable "instance_type" {
  type    = list(any)
  default = ["t2.micro", "t2.large", "t2.small"]
}

  variable "region" {
    default = "us-east-2"
}