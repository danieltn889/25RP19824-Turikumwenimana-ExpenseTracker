output "api_container_id" {
  value       = docker_container.api.id
  description = "API container ID"
}

output "frontend_container_id" {
  value       = docker_container.frontend.id
  description = "Frontend container ID"
}

output "database_container_id" {
  value       = docker_container.database.id
  description = "Database container ID"
}

output "api_url" {
  value       = "http://localhost:3000"
  description = "API endpoint URL"
}

output "frontend_url" {
  value       = "http://localhost"
  description = "Frontend URL"
}

output "database_url" {
  value       = "postgresql://expenseuser:expensepass@localhost:5432/expensedb"
  description = "Database connection string"
  sensitive   = true
}

output "network_name" {
  value       = docker_network.app_network.name
  description = "Docker network name"
}
