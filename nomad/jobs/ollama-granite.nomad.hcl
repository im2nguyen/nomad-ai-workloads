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
      # Action to load model from
      # https://ollama.com/library
      # action "download-ollama-library-model" {
      #   command = "/usr/bin/ollama"
      #   args = [
      #     "pull",
      #     "OLLAMA_LIBRARY_MODEL_NAME"
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
DEFAULT_MODELS="granite3.2-vision"
OFFLINE_MODE="True"
ENABLE_SIGNUP="False"
WEBUI_BANNERS="[{\"id\": \"cloud-banner\",\"type\": \"info\",\"title\": \"INFO\",\"content\": \"This instance of Open WebUI is connected to Ollama backends running in AWS and GCP - granite-code is running in AWS and granite3.2-vision is running in GCP.\",\"dismissible\": \"False\",\"timestamp\": \"1000\"}]"
ENABLE_OPENAI_API="False"
STORAGE_PROVIDER="s3"
{{ with nomadVar "nomad/jobs/ollama" }}
S3_ACCESS_KEY_ID="{{ .aws_access_key_id }}"
S3_SECRET_ACCESS_KEY="{{ .aws_access_secret_key }}"
S3_ENDPOINT_URL="https://s3.{{ .aws_default_region }}.amazonaws.com"
S3_REGION_NAME="{{ .aws_default_region }}"
S3_BUCKET_NAME="{{ .openwebui_bucket }}"
{{ end }}
EOH
            destination = "local/env.txt"
            env         = true
      }
      template {
            data        = <<EOH
INSERT INTO user (id,name,email,role,profile_image_url,last_active_at,updated_at,created_at) VALUES('');

INSERT INTO auth (id,email,password,active) VALUES ('');
EOH
            destination = "local/create-admin-user.sql"
            env         = false
      }
      action "create-admin-user" {
        command = "/bin/bash"
        args = [
          "-c",
          "apt-get update && apt-get install -y sqlite3 && echo 'Running SQL insert commands...' && sqlite3 /app/backend/data/webui.db < /local/create-admin-user.sql && echo 'Finished running SQL commands'"
        ]
      }
    }
  }
}