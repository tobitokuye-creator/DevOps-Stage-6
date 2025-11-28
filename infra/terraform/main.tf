# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create SSH Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/devops-key.pem"
  file_permission = "0600"
}

# Create EC2 Instance
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    domain_name  = var.domain_name
    github_repo  = var.github_repo
  })

  tags = {
    Name = "DevOps-Stage6-Server"
    Environment = "production"
    Project = "TodoApp"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP
resource "aws_eip" "app_eip" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name = "DevOps-Stage6-EIP"
  }
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

# Trigger Ansible Provisioning
resource "null_resource" "run_ansible" {
  triggers = {
    instance_id = aws_instance.app_server.id
    always_run  = timestamp()
  }

  provisioner "local-exec" {
    command = "sleep 60 && cd ${path.module}/../ansible && ansible-playbook -i inventory.ini playbook.yml"
  }

  depends_on = [
    local_file.ansible_inventory,
    aws_eip.app_eip
  ]
}
