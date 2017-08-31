data "aws_ami" "ubuntu_14_ami" {
  most_recent = true

  filter {
    name   = "owner-id"
    values = ["099720109477"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/*/ubuntu-*-14.04-*-server-*"]
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
    values = ["standard"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }
}

resource "aws_instance" "mixlib_install_sh" {
  count = 1

  ami           = "${data.aws_ami.ubuntu_14_ami.id}"
  instance_type = "${var.aws_instance_type}"
  key_name      = "es-infrastructure"

  associate_public_ip_address = true

  subnet_id         = "subnet-11ac0174" # Planet Releng Public Subnet
  source_dest_check = false

  vpc_security_group_ids = [
    "sg-96274af3",
  ]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.connection_private_key}")}"
    agent       = "${var.connection_agent}"
    timeout     = "10m"
  }

  tags {
    # ChefOps's AWS standard tags:
    X-Dept        = "EngServ"
    X-Contact     = "pwright"
    X-Production  = "false"
    X-Environment = "acceptance"
    X-Application = "mixlib-install"
  }

  provisioner "file" {
    source      = "../../.acceptance_data/ubuntu_install_url.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "file" {
    source      = "../../.acceptance_data/ubuntu_install_checksum.sh"
    destination = "/tmp/install_checksum.sh"
  }

  provisioner "file" {
    source      = "../../.acceptance_data/ubuntu_install_metadata.sh"
    destination = "/tmp/install_metadata.sh"
  }

  provisioner "file" {
    source      = "../../.acceptance_data/ubuntu_install_bad.sh"
    destination = "/tmp/install_bad.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install.sh",
      "chmod +x /tmp/install_checksum.sh",
      "chmod +x /tmp/install_metadata.sh",
      "chmod +x /tmp/install_bad.sh",
    ]
  }
}
