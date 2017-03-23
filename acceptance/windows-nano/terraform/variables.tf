# Region to create infrastructure in
variable "aws_region" {
  type    = "string"
  default = "us-west-2"
}

variable "aws_instance_type" {
  type    = "string"
  default = "t2.micro"
}
