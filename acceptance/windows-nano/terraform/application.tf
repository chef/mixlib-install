data "aws_ami" "windows_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Nano-Base-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }
}

resource "aws_instance" "windows_server_nano_ami" {
  count = 1

  ami           = "${data.aws_ami.windows_ami.id}"
  instance_type = "${var.aws_instance_type}"
  key_name      = "es-infrastructure"

  associate_public_ip_address = true

  subnet_id         = "subnet-11ac0174" # Planet Releng Public Subnet
  source_dest_check = false

  vpc_security_group_ids = [
    "sg-96274af3",
  ]

  tags {
    # ChefOps's AWS standard tags:
    X-Dept        = "EngServ"
    X-Contact     = "pwright"
    X-Production  = "false"
    X-Environment = "acceptance"
    X-Application = "mixlib-install"
  }
}
