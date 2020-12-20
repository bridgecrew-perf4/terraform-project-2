output "ec2_ip" {
  value = local.use_eip == 1 ? join("", data.aws_eip.ec2_ip.*.public_ip) : aws_instance.vm.public_ip
}

output "ssh_key_path" {
  value = local.private_key_filename
}

output "ec2_sg" {
  value = aws_security_group.ec2_security_group.id
}

output "vm_id" {
  value = aws_instance.vm.id
}