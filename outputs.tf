output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = module.aws_lb.target_groups
}