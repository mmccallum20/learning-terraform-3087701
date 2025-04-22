variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}

variable "aws_security_group" {
  type = list(string)
  default     = ["default"]
}

variable "aws_lb" {
  description = "Configuration for the AWS Application Load Balancer"
  type = object({
    name               = string
    internal           = bool
    security_groups    = list(string)
    subnets            = list(string)
    enable_deletion_protection = bool
  })
  default = {
    name               = "my-load-balancer"
    internal           = false
    security_groups    = ["sg-0123456789abcdef0"]
    subnets            = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    enable_deletion_protection = false
  }
}

