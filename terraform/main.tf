terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Network
resource "docker_network" "app_network" {
  name = "25rp19824-turikumwenimana-network"
}

# Database Image
resource "docker_image" "postgres" {
  name         = "postgres:15-alpine"
  keep_locally = true
}

# API Image
resource "docker_image" "api" {
  name         = "danieltn889/25rp19824-turikumwenimana-api:latest"
  keep_locally = true
  build {
    context      = "${path.module}/../api-service"
    dockerfile   = "Dockerfile"
    tag          = ["danieltn889/25rp19824-turikumwenimana-api:latest"]
    build_args = {
      NODE_ENV = "production"
    }
  }
}

# Frontend Image
resource "docker_image" "frontend" {
  name         = "danieltn889/25rp19824-turikumwenimana-frontend:latest"
  keep_locally = true
  build {
    context    = "${path.module}/../frontend-service"
    dockerfile = "Dockerfile"
    tag        = ["danieltn889/25rp19824-turikumwenimana-frontend:latest"]
  }
}

# Database Container
resource "docker_container" "database" {
  name     = "25rp19824-turikumwenimana-db"
  image    = docker_image.postgres.image_id
  restart_policy = "unless-stopped"
  must_run = true

  env = [
    "POSTGRES_USER=expenseuser",
    "POSTGRES_PASSWORD=expensepass",
    "POSTGRES_DB=expensedb"
  ]

  ports {
    internal = 5432
    external = 5432
  }

  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = "db_data_volume"
  }

  volumes {
    container_path = "/docker-entrypoint-initdb.d/init.sql"
    host_path      = abspath("${path.module}/../init-db.sql")
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U expenseuser"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "10s"
  }
}

# API Container
resource "docker_container" "api" {
  name     = "25rp19824-turikumwenimana-api"
  image    = docker_image.api.image_id
  restart_policy = "unless-stopped"
  must_run = true

  env = [
    "DB_HOST=25rp19824-turikumwenimana-db",
    "DB_USER=expenseuser",
    "DB_PASSWORD=expensepass",
    "DB_NAME=expensedb",
    "PORT=3000",
    "NODE_ENV=production"
  ]

  ports {
    internal = 3000
    external = 3000
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [docker_container.database]

  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost:3000/health"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "10s"
  }
}

# Frontend Container
resource "docker_container" "frontend" {
  name     = "25rp19824-turikumwenimana-frontend"
  image    = docker_image.frontend.image_id
  restart_policy = "unless-stopped"
  must_run = true

  ports {
    internal = 80
    external = 80
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [docker_container.api]

  healthcheck {
    test         = ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "10s"
  }
}

# Volume
resource "docker_volume" "db_data" {
  name = "db_data_volume"
}

output "api_endpoint" {
  value = "http://localhost:3000"
}

output "frontend_endpoint" {
  value = "http://localhost"
}

output "database_connection" {
  value = "postgresql://expenseuser:expensepass@localhost:5432/expensedb"
}
