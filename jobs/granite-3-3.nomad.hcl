job "ollama" {
  type = "service"
  node_pool = "large"

  group "ollama" {
    count = 1
    network {
      port "ollama" {
        to = 11434
        static = 8080
      }
    }

    task "ollama-task" {
      driver = "docker"

      service {
        name = "ollama-backend"
        port = "ollama"
        provider = "nomad"
      }
      config {
        image = "ollama/ollama"
        ports = ["ollama"]
      }

      resources {
        cpu    = 9100
        memory = 15000
      }
    }

    task "download-granite3.3-model" {
        driver = "exec"
        lifecycle {
            hook = "poststart"
        }
        resources {
            cpu    = 100
            memory = 100
        }
        template {
            data        = <<EOH
{{ range nomadService "ollama-backend" }}
OLLAMA_BASE_URL="http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOH
            destination = "local/env.txt"
            env         = true
      }
        config {
            command = "/bin/bash"
            args = [
                "-c",
                "curl -X POST ${OLLAMA_BASE_URL}/api/pull -d '{\"name\": \"granite3.3:2b\"}'"
            ]
        }
    }
  }
}