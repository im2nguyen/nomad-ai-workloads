job "ollama-granite-4-0" {
  type = "service"
  node_pool = "medium"

  group "ollama-granite-4-0" {
    count = 1
    network {
      port "ollama" {
        to = 11434
        static = 8080
      }
    }

    task "ollama-task-granite-4-0" {
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
        cpu    = 4000
        memory = 3500
      }
    }

    task "download-granite4.0-model" {
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
                "curl -X POST ${OLLAMA_BASE_URL}/api/pull -d '{\"name\": \"hf.co/ibm-granite/granite-4.0-tiny-preview-GGUF:Q4_K_M\"}'"
            ]
        }
    }
  }
}