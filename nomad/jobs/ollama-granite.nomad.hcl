job "ollama" {
  type = "service"

  # node_pool = "gcp"

  group "ollama-group" {
    count = 1
    network {
      port "ollama" {
        to = 11434
        static = 11434
      }
      port "open-webui" {
        to = 8080
        static = 80
      }
    }

    task "ollama-task" {
      driver = "docker"

      config {
        image = "ollama/ollama"
        ports = ["ollama"]
      }
      resources {
        cpu    = 6000
        memory = 11000
      }
      action "get-granite-model" {
        command = "/usr/bin/ollama"
        args = [
          "pull",
          "granite3.2-vision"
        ]
      }
    }

    task "open-webui-task" {
      driver = "docker"

      config {
        image = "ghcr.io/open-webui/open-webui:main"
        ports = ["open-webui"]
      }
      resources {
        cpu    = 1500
        memory = 3000
      }
      env {
        OLLAMA_BASE_URL="http://${attr.unique.network.ip-address}:11434"
        ENV="dev"
        WEBUI_AUTH="False"
        DEFAULT_MODELS="granite3.2-vision"
        # Disables update checks and automatic model downloads
        OFFLINE_MODE="True"
      }
    }
  }
}