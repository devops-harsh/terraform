provider "aws" {
  region = "ap-south-1"
  alias  = "ap-south-1"
}

resource "aws_vpc" "terraform-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-terraform"
  }
}

resource "aws_subnet" "public-subnet-A" {
  vpc_id                  = aws_vpc.terraform-vpc.id //connecting to the vpc
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-B" {
  vpc_id                  = aws_vpc.terraform-vpc.id //connecting to the vpc
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1b"

  tags = {
    Name = "public-subnet-2"
  }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terraform-vpc.id
  tags = {
    Name = "vpc-internet-gateway"
  }

}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "route-table"
  }

}

// any traffic leaving my two subnets in private sent the traffic to the igw. the incomming trrafic always come with specific destination. such as url of ALB. so we need to configure for outbound traffic from subnet.
resource "aws_route_table_association" "RT-subnet-A" {
  route_table_id = aws_route_table.RT.id
  subnet_id      = aws_subnet.public-subnet-A.id
}

resource "aws_route_table_association" "RT-subnet-B" {
  route_table_id = aws_route_table.RT.id
  subnet_id      = aws_subnet.public-subnet-B.id
}


resource "aws_security_group" "prod-sg" {
  name        = "production-security-group"
  description = "this is production security group for HTTP and ssh"
  vpc_id      = aws_vpc.terraform-vpc.id

  tags = {
    Name = "prod-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh" {
  security_group_id = aws_security_group.prod-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow-http" {
  security_group_id = aws_security_group.prod-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "out-any" {
  security_group_id = aws_security_group.prod-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "instance-access-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

//vpc endpoint - the aws reources as s3 and more which we want to access without internet facing. its internal private connection with that resource and vpc 
resource "aws_s3_bucket" "vpc-proj-com" {
  bucket = "vpc.proj.com"

  tags = {
    Name        = "vpc.proj.com"
    Environment = "prod"
  }
}

resource "aws_s3_bucket" "backend-bucket" {
  bucket = "vpc.proj.backend.state.com"
  tags ={
    Name = "backend"
  }
  
}

//i am policy to list down and access and put the files in bucket
resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "ec2-s3-vpc-iam-policy"
  description = "allow ec2 to access the s3 object"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.vpc-proj-com.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]

        Resource = "${aws_s3_bucket.vpc-proj-com.arn}/*"

      }
    ]
  })
}

// iam role for ec2 to access the policy
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "ec2-s3-access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

// iam role and policy attachement
resource "aws_iam_role_policy_attachment" "ec2_s3_policy-role_attachement" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn

}

// ec2 can't directly use the IAM role we are creating the instance_profile to attach in the ec2
resource "aws_iam_instance_profile" "ec2_s3_role-policy" {
  name = "ec2-s3-vpc-profile"
  role = aws_iam_role.ec2_s3_access_role.name
}

resource "aws_s3_object" "server-1_index" {
  bucket = aws_s3_bucket.vpc-proj-com.id
  key    = "server1/index.html"
  source = "/root/projects/terraform/vpc/userdata1/index.html"
}

resource "aws_s3_object" "server-2_index" {
  bucket = aws_s3_bucket.vpc-proj-com.id
  key    = "server2/index.html"
  source = "/root/projects/terraform/vpc/userdata2/index.html"
}

resource "aws_instance" "instance-1" {
  ami                    = "ami-01a00762f46d584a1"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public-subnet-A.id
  vpc_security_group_ids = [aws_security_group.prod-sg.id]
  key_name               = aws_key_pair.ssh-key.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_s3_role-policy.name

  tags = {
    Name = "instance-a"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  # provisioner "file" {
  #   source = "/root/projects/terraform/vpc/userdata1/index.html"
  #   destination = "/tmp/index.html"
  # }

  provisioner "remote-exec" {
    inline = [
      "echo 'ec2 instance connected' ",
      "sudo apt update -y ",
      "sudo apt install nginx awscli -y",
      "aws s3 cp s3://vpc.proj.com/server1/index.html /tmp/index.html",
      "sudo cp /tmp/index.html /home/ubuntu/",
      "sudo rm -rf /var/www/html/*",
      "sudo cp /home/ubuntu/index.html /var/www/html/",
      "sudo systemctl restart nginx",
      "echo 'webiste deployed' "
    ]
  }

}

resource "aws_instance" "instance-2" {
  ami                    = "ami-01a00762f46d584a1"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public-subnet-B.id
  vpc_security_group_ids = [aws_security_group.prod-sg.id]
  key_name               = aws_key_pair.ssh-key.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_s3_role-policy.name


  tags = {
    Name = "instance-b"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  #  provisioner "file" {
  #   source = "/root/projects/terraform/vpc/userdata2/index.html"
  #   destination = "/tmp/index.html"
  # }

  provisioner "remote-exec" {
    inline = [
      "echo 'ec2 instance connected' ",
      "sudo apt update ",
      "sudo apt install nginx -y",
      "sudo apt install awscli -y",
      "aws s3 cp s3://vpc.proj.com/server2/index.html /tmp/index.html",
      "sudo cp /tmp/index.html /home/ubuntu/",
      "sudo rm -rf /var/www/html/*",
      "sudo cp /home/ubuntu/index.html /var/www/html/",
      "sudo systemctl restart nginx",
      "echo 'webiste deployed' "
    ]
  }

}

resource "aws_alb" "prod-alb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.prod-sg.id]
  subnets         = [aws_subnet.public-subnet-A.id, aws_subnet.public-subnet-B.id]

  tags = {
    name = "prod-alb"
  }

}

resource "aws_lb_target_group" "prod_target_group" {
  name     = "prod-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_alb_target_group_attachment" "alb-target_group" {
  target_group_arn = aws_lb_target_group.prod_target_group.arn
  target_id        = aws_instance.instance-1.id
  port             = 80
}

resource "aws_alb_target_group_attachment" "alb-target_group-2" {
  target_group_arn = aws_lb_target_group.prod_target_group.arn
  target_id        = aws_instance.instance-2.id
  port             = 80
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.prod-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.prod_target_group.arn
    type             = "forward"
  }
}


resource "aws_dynamodb_table" "terraform_state_lock" {
  name             = "terraform-state-lock"
  hash_key         = "LOCK-ID" 
  billing_mode     = "PAY_PER_REQUEST"
  attribute {
    name = "LOCK-ID"
    type = "S"
  }

  tags = {
    Name = "terraform-lock"
  }
  
}




