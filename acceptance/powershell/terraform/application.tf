data "aws_ami" "windows_ami" {
  most_recent = true
  filter {
    name = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name = "name"
    values = ["Windows_Server-2012-R2*-English-*-Base-*"]
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

resource "aws_instance" "mixlib_install_ps1" {
  count = 1

  ami           = "${data.aws_ami.windows_ami.id}"
  instance_type = "${var.aws_instance_type}"
  key_name      = "es-infrastructure"

  subnet_id         = "subnet-19ac017c" # Planet Releng Private Subnet
  source_dest_check = false

  vpc_security_group_ids = [
    "sg-96274af3",
  ]

  # TODO: What needs to happen here?
  connection {
    type         = "winrm"
  }

  provisioner "file" {
    source      = "../../.acceptance_data/install.ps1"
    destination = "/tmp/install.ps1"
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe -file /tmp/install.ps1"
    ]
  }
}
