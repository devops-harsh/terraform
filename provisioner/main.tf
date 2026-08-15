provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "dev-vpc" {
    cidr_block = var.vpc_cidr
    tags = {
      name ="dev-vpc"
    }
}

resource "aws_key_pair" "ssh-key" { 
    key_name = "terraform-harsh-key"
    public_key = file("~/.ssh/id_rsa.pub") // reads the existing one and upload that public key to AWS.
}

resource "aws_subnet" "dev-subnet-a" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.dev-subnet-cidr
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true // it will assign the public ip to the ec2 in this subnet
    tags = {
      name = "dev-subnet-a"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev-vpc.id 
  tags = {
    name = "dev-vpc-igw"
  }
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.dev-vpc.id
  route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    name= "dev-route-table"
  }
}

resource "aws_route_table_association" "name" { // route table association is used to map the subnet to the route table. 
  subnet_id = aws_subnet.dev-subnet-a.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "dev-sg" {
  vpc_id = aws_vpc.dev-vpc.id
  name = "dev-vpc-sg"

    tags = {
    name = "dev-vpc-sg"
  }

}

#   ingress {
#     from_port = 22
#     to_port = 22
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#    ingress {
#     from_port = 80
#     to_port = 80
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  

#   egress { // outbound traffic
#     from_port = 0
#     to_port = 0 
#     protocol = "-1" // any protocol
#     cidr_block = ["0.0.0.0/0"]
#   }

#   tags = {
#     name = "dev-vpc-sg"
#   }
# }

resource "aws_vpc_security_group_egress_rule" "dev-sg-eng" {
  security_group_id = aws_security_group.dev-sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "-1"
  to_port     = 0
}

resource "aws_vpc_security_group_ingress_rule" "dev-sg-ing-rule-1" {
  security_group_id = aws_security_group.dev-sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "dev-sg-ing-rule-2" {
  security_group_id = aws_security_group.dev-sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 5000
  ip_protocol = "tcp"
  to_port     = 5000
}

resource "aws_vpc_security_group_ingress_rule" "dev-sg-ing-rule-3" {
  security_group_id = aws_security_group.dev-sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}


resource "aws_instance" "dev-instance" {
    ami = "ami-01a00762f46d584a1"
    subnet_id = aws_subnet.dev-subnet-a.id 
    instance_type = "t3.micro"
    key_name = aws_key_pair.ssh-key.key_name
    vpc_security_group_ids = [aws_security_group.dev-sg.id] // security group we want to attach

    connection { //specifiying how to connect the ec2 instance
      type = "ssh"
      user = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host  = self.public_ip //public ip of the ec2
    }

    provisioner "file" { //file provisioner is used to copy from the local files to the ec2 instance.
     source = "/root/projects/terraform/provisioner/app.py" //where the file currnetly has in my local instance
     destination = "/tmp/app.py" // where i want to put the in the ec2.
    }

    provisioner "remote-exec" { //remote provisioner is used to execute the code inside the ec2 instance.
    inline = [
        "echo 'ec2 connected successfully' ",
        "sudo apt update -y ",
        "sudo apt-get install -y python3-pip",
        "cp /tmp/app.py /home/ubuntu/",
        "cd /home/ubuntu",
        "python3 -m venv venv",
        "venv/bin/pip install flask",
        "sudo venv/bin/python app.py > app.log",
    ]
    }
}








