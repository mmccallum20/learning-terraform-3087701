output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = module.alb.target_groups
}