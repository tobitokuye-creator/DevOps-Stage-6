# Use a specific Ubuntu 22.04 AMI for eu-north-1
locals {
  ubuntu_ami = "ami-0705384c0b33c194c" # Ubuntu 22.04 LTS for eu-north-1
}

# Uncomment this if you fix IAM permissions
# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical
# 
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }
# 
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# Create SSH Key Pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/devops-key.pem"
  file_permission = "0600"
}

# Create EC2 Instance
resource "aws_instance" "app_server" {
  ami           = local.ubuntu_ami  # Changed from data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    domain_name = var.domain_name
    github_repo = var.github_repo
  })

  tags = {
    Name        = "DevOps-Stage6-Server"
    Environment = "production"
    Project     = "TodoApp"
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes        = [user_data]
  }
}

# Elastic IP
resource "aws_eip" "app_eip" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name = "DevOps-Stage6-EIP"
  }

  depends_on = [aws_instance.app_server]
}

# Generate Ansible Inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    server_ip   = aws_eip.app_eip.public_ip
    private_key = "${path.module}/devops-key.pem"
  })
  filename = "${path.module}/../ansible/inventory.ini"

  depends_on = [aws_eip.app_eip]
}

# Provisioner to run Ansible (runs only after first creation)
resource "null_resource" "run_ansible" {
  triggers = {
    instance_id = aws_instance.app_server.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for server to be ready..."
      sleep 90
      echo "Running Ansible playbook..."
      cd ${path.module}/../ansible && ansible-playbook -i inventory.ini playbook.yml -vv
    EOT
  }

  depends_on = [
    local_file.ansible_inventory,
    aws_eip.app_eip
  ]
}