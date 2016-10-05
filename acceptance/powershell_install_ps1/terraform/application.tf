data "aws_ami" "windows_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["Windows_Server-2012-R2*-English-*-Base-*"]
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

resource "aws_instance" "mixlib_install_ps1" {
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

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = "${var.admin_password}"
    timeout  = "10m"
  }

  user_data = <<EOF
<script>
  winrm quickconfig -q & winrm set winrm/config/winrs @{MaxMemoryPerShellMB="300"} & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"}
</script>
<powershell>
  Set-ExecutionPolicy -ExecutionPolicy Bypass
  netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
  $admin = [adsi]("WinNT://./administrator, user")
  $admin.psbase.invoke("SetPassword", "${var.admin_password}")
</powershell>
EOF

  tags {
    # ChefOps's AWS standard tags:
    X-Dept        = "EngServ"
    X-Contact     = "pwright"
    X-Production  = "false"
    X-Environment = "development"
    X-Application = "mixlib-install"
  }

  provisioner "file" {
    source      = "../../.acceptance_data/powershell_install.ps1"
    destination = "/tmp/install.ps1"
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe -file /tmp/install.ps1",
    ]
  }
}
