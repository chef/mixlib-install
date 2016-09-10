# Region to create infrastructure in
variable "aws_region" {
  type    = "string"
  default = "us-west-2"
}

variable "aws_instance_type" {
  type    = "string"
  default = "t2.micro"
}

# Used to indicidate whether the environment should be treated as "prod"
# This is mainly used for the `X-Production` AWS tag.
variable "production" {
  default = "false"
}

variable "connection_private_key" {
  description = "File path to AWS keypair private key to provision with"
  default     = "~/.ssh/es-infrastructure.pem"
}
