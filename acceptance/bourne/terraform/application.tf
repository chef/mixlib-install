resource "aws_instance" "mixlib_install_sh" {
  count = 1

  ami           = "${lookup(var.aws_ami, var.aws_region)}"
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
