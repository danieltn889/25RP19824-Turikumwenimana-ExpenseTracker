variable "project_name" {
  description = "Project name"
  type        = string
  default     = "25rp19824-turikumwenimana"
}

variable "docker_user" {
  description = "Docker Hub username"
  type        = string
  default     = "danieltn889"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "expenseuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "expensepass"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "expensedb"
}
