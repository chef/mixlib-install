output "instance_ids" {
  value = "${join(",", aws_instance.mixlib_install_ps1.*.id)}"
}

output "private_ip_addresses" {
  value = "${join(",", aws_instance.mixlib_install_ps1.*.private_ip)}"
}
