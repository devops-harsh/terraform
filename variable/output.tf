output "public_ip" {
  description = "public ip of the ec2"
  value = aws_instance.var-inst.public_ip
}