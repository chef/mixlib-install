data "aws_ami" "centos_7_ami" {
  most_recent = true

  filter {
    name   = "owner-id"
    values = ["679593333241"]
  }

  filter {
    name   = "name"
    values = ["CentOS Linux 7*"]
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

  ami           = "${data.aws_ami.centos_7_ami.id}"
  instance_type = "${var.aws_instance_type}"
  key_name      = "es-infrastructure"

  associate_public_ip_address = true

  subnet_id         = "subnet-11ac0174" # Planet Releng Public Subnet
  source_dest_check = false

  vpc_security_group_ids = [
    "sg-96274af3",
  ]

  connection {
    user        = "centos"
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
    source      = "../../.acceptance_data/centos_install_url.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "file" {
    source      = "../../.acceptance_data/centos_install_checksum.sh"
    destination = "/tmp/install_checksum.sh"
  }

  provisioner "file" {
    source      = "../../.acceptance_data/centos_install_metadata.sh"
    destination = "/tmp/install_metadata.sh"
  }

  provisioner "file" {
    source      = "../../.acceptance_data/centos_install_bad.sh"
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
