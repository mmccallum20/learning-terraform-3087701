output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = module.blog_alb.target_groups
}