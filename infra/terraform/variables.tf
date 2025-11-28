variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key name"
  type        = string
  default     = "devops-stage6-key"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "mlle.crabdance.com"
}

variable "email_address" {
  description = "Email for SSL certificates"
  type        = string
  default     = "kuyeoluwatobi88@gmail.com"
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/tobitokuye-creator/DevOps-Stage-6.git"
}
