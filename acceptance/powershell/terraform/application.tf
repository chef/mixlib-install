resource "aws_instance" "mixlib_install_ps1" {
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
    type         = "winrm"
    host         = "${self.private_ip}"
    private_key  = "${file("${var.connection_private_key}")}"
    agent        = "${var.connection_agent}"
  }

  # provisioner "file" {
  #   source      = "${var.connection_private_key}"
  #   destination = "/home/ubuntu/.ssh/id_rsa"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo chmod 0400 /home/ubuntu/.ssh/id_rsa"
  #   ]
  # }

  provisioner "file" {
    source      = "../../.acceptance_data/install.ps1"
    destination = "/tmp/install.ps1"
  }

  provisioner "remote-exec" {
    script = "powershell.exe -file /tmp/install.ps1"
  }
}
