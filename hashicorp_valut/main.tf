provider "aws" {
    region = "ap-south-1"
}

provider "vault" { // provider for secrets 
  address = "http://154.61.75.245:8200"
  skip_child_token = true

  auth_login {
    path = "auth/approle/login"
    parameters = {
      role_id = "role-id" 
      secret_id = "secret-id"
    }
  }
}

data "vault_kv_secret_v2" "kv-secret" { // used to read through the resources. retrives the information from extrnal sources and provide the data to all.
  mount = "secret" //path or name of secret engines secret method. we are using KV which is key-value pair
  name  = "test-secret" // name of the secret inside the that secret method
}

data "vault_kv_secret_v2" "kv-bucket-secret" { 
  mount = "secret" 
  name  = "bucket" 
}


resource "aws_instance" "secret_ec2_instance" {
  ami = var.ami
  instance_type = "t2.micro"

  tags = {
      # name = "secret-instance"
      secret = data.vault_kv_secret_v2.kv-secret.data["username"]
  }
}

resource "aws_s3_bucket" "secret_bucket" {
   bucket = data.vault_kv_secret_v2.kv-bucket-secret.data["bukcet_name"]
}
output "tag-name" {
  value = aws_instance.secret_ec2_instance.tags
  sensitive = true
}
