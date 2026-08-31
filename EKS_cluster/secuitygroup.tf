resource "aws_security_group" "eks-sg" {
  vpc_id = module.vpc.default_vpc_id
  tags = {
    Name = "eks-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress" {
  security_group_id = aws_security_group.eks-sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_out" {
  security_group_id = aws_security_group.eks-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}