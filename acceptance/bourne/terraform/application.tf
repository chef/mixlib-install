data "aws_ami" "ubuntu_14_ami" {
  most_recent = true
  filter {
    name = "owner-id"
    values = ["099720109477"]
  }
  filter {
    name = "name"
    values = ["ubuntu/images/*/ubuntu-*-14.04-*-server-*"]
  }
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "virtualization-type" 
    values = ["hvm"]
  }
  filter {
    name = "block-device-mapping.volume-type"
    values = ["gp2"]
  }
  filter {
    name = "image-type"
    values = ["machine"]
  }
}

resource "aws_instance" "mixlib_install_sh" {
  count = 1

  ami           = "${data.aws_ami.ubuntu_14_ami.id}"
  instance_type = "${var.aws_instance_type}"
  key_name      = "es-infrastructure"

  subnet_id         = "subnet-19ac017c" # Planet Releng Private Subnet
  source_dest_check = false

  vpc_security_group_ids = [
    "sg-96274af3",
  ]

  connection {
    host         = "${self.private_ip}"
    user         = "ubuntu"
    private_key  = "${file("${var.connection_private_key}")}"
    agent        = "${var.connection_agent}"
  }

  provisioner "file" {
    source      = "../../.acceptance_data/install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install.sh",
      "sudo bash /tmp/install.sh"
    ]
  }
}
