output "instance_ids" {
  value = "${join(",", aws_instance.mixlib_install_sh.*.id)}"
}

output "private_ip_addresses" {
  value = "${join(",", aws_instance.mixlib_install_sh.*.private_ip)}"
}
