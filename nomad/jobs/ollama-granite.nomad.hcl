job "ollama" {
  type = "service"

  group "ollama-gcp-group" {
    constraint {
        attribute = "${meta.cloud}"
        operator  = "="
        value     = "gcp"
    }
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
        name = "ollama-backend-gcp"
        port = "ollama"
        provider = "nomad"
        address = "${meta.externalAddress}"
      }
      config {
        image = "ollama/ollama"
        ports = ["ollama"]
      }

      resources {
        cpu    = 2500
        memory = 7000
      }
    }

    task "download-granite-vision-model" {
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
{{ range nomadService "ollama-backend-gcp" }}
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
                "curl -X POST ${OLLAMA_BASE_URL}/api/pull -d '{\"name\": \"granite3.2-vision\"}'"
            ]
        }
    }

  }
  group "ollama-aws-group" {
    constraint {
        attribute = "${meta.cloud}"
        operator  = "="
        value     = "aws"
    }
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
        name = "ollama-backend-aws"
        port = "ollama"
        provider = "nomad"
      }
      config {
        image = "ollama/ollama"
        ports = ["ollama"]
      }

      resources {
        cpu    = 2500
        memory = 7000
      }
      # action "download-granite-code-model" {
      #   command = "/usr/bin/ollama"
      #   args = [
      #     "pull",
      #     "granite-code"
      #   ]
      # }
    }

    task "download-granite-code-model" {
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
{{ range nomadService "ollama-backend-aws" }}
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
                "curl -X POST ${OLLAMA_BASE_URL}/api/pull -d '{\"name\": \"granite-code\"}'"
            ]
        }
    }
  }

  group "open-webui" {
    constraint {
        attribute = "${meta.isPublic}"
        operator  = "="
        value     = "true"
    }
    constraint {
        attribute = "${meta.cloud}"
        operator  = "="
        value     = "aws"
    }
    count = 1

    network {
      port "open-webui" {
        to = 8080
        static = 80
      }
    }

    task "open-webui-task" {
      driver = "docker"

      service {
        name = "ollama-frontend"
        port = "open-webui"
        provider = "nomad"

        check {
          type     = "http"
          name     = "open-webui-health"
          path     = "/"
          interval = "20s"
          timeout  = "5s"
        }
      }

      config {
        image = "ghcr.io/open-webui/open-webui:main"
        ports = ["open-webui"]
      }
      resources {
        cpu    = 1000
        memory = 2000
      }
      template {
            data        = <<EOH
OLLAMA_BASE_URLS={{ range nomadService "ollama-backend-aws" }}http://{{ .Address }}:{{ .Port }}{{ end }};{{ range nomadService "ollama-backend-gcp" }}http://{{ .Address }}:{{ .Port }}{{ end }}

ENV="dev"
WEBUI_AUTH=False
DEFAULT_MODELS="granite3.2-vision"
# Disables update checks and automatic model downloads
OFFLINE_MODE=True
WEBUI_BANNERS="[{\"id\": \"cloud-banner\",\"type\": \"info\",\"title\": \"INFO\",\"content\": \"This instance of Open WebUI is connected to Ollama backends running in AWS and GCP - granite-code is running in AWS and granite3.2-vision is running in GCP.\",\"dismissible\": \"False\",\"timestamp\": \"1000\"}]"
ENABLE_OPENAI_API=False
EOH
            destination = "local/env.txt"
            env         = true
      }
    }
  }
}