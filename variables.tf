variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}

variable "aws_security_group" {
  type = list(string)
  default     = ["default"]
}
