variable "ami_id" {
  description = "The AMI ID for the Jenkins server"
  type        = string
  
}

variable "instance_type" {
  description = "The instance type for the Jenkins server"
  type        = string
  
}

variable "key_name" {
  description = "The key name for the Jenkins server"
  type        = string
  
}

variable "main-region" {
  description = "The AWS region to deploy resources"
  type        = string
  
}

variable "security_group_id" {
  description = "The security group ID to attach to the instance"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID where the instance will be deployed"
  type        = string
}
