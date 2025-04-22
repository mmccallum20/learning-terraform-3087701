output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = var.aws_lb.target_groups
}