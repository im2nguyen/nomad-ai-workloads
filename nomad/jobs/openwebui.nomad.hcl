job "open-webui" {
  type = "service"

  group "open-webui" {
    constraint {
        attribute = "${meta.cloud}"
        operator  = "="
        value     = "aws"
    }
    constraint {
        attribute = "${meta.isPublic}"
        operator  = "="
        value     = "true"
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
        name = "open-webui-svc"
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
OLLAMA_BASE_URL={{ range nomadService "ollama-backend" }}http://{{ .Address }}:{{ .Port }}{{ end }}
ENV="dev"
DEFAULT_MODELS="granite3.2-vision"
OFFLINE_MODE="True"
ENABLE_SIGNUP="False"
ENABLE_OPENAI_API="False"
STORAGE_PROVIDER="s3"
{{ with nomadVar "nomad/jobs/open-webui" }}
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
      # user-email: admin@local.local
      # bcrypt the desired password and place the value into the auth table
      # (substitute BCRYPTED_PASSWORD with value)
      template {
            data        = <<EOH
INSERT INTO user (id,name,email,role,profile_image_url,last_active_at,updated_at,created_at) VALUES('ec80e845-976d-4f0e-beb7-30212e69da61','admin','admin@local.local','admin','data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAAAXNSR0IArs4c6QAABUdJREFUeF7tnFtsFFUcxr+Zve9sGigUo4ESL2AVBBKq4gVDomLkAURBtK2mRBNDfNBo9MFEHtCYmPggJjyYeCttilarPHg3iihgFKIiCaUtl6hUQFEr7ux2d2d3zPRhu8e2odmZTr9J/vPW2Z1zvvn9+m3PzLTV/n2l1oZsNAQ0EULjYjiICOHyIULIfIgQEcJGgCyP/AwRIWQEyOJIQ0QIGQGyONIQEUJGgCyONESEkBEgiyMNESFkBMjiSENECBkBsjjSEBFCRoAsjjREhJARIIsjDREhZATI4khDRAgZAbI40hARQkaALI40RISQESCLIw0RIWQEyOJIQ0SIhwRCMYTqGpUBbSuN0tmDHk7i71CBbki08WlEFz86ipjZMQ927i9/SXo0W6CFGE090BKzRqEoHNqG3HebPULk7zCBFaLXLkBy7Vdj0rKzf8DsbPCXpEezBVZI/JZ2hOeuGhdDpvt6lAZ7PcLk3zCBFZJq/Q0IxcYlZR1/D0O7HvSPpEczBVJI+NJ1iK94WUVgZYFworzPtjIw2+Z4hMm/YQIpJLl2N/TahSPwzQFYv36GSEOrQi77yd0onvzcP5oezBQ4IVq0BsZ9x52/6C6ffv7752H1v4nkhh8UJMXTe5H9YLUHmPwbInBColdvRnTRIxWEbJjb58IumDDuPQwtecHIayUL6TcuAuyif0RdzhQ4IUZTL7TEzPJpl/48hMzOFcNfx659FpGFmxQkuW+eROHwqy4x+Xd4oIToMxYheccuhc7Q7k2wjnYN79MSdTCajiivlwb7kOm+zj+iLmcKlJD4rR0I199e8ZGUR/r1CxUExoYfoaUqV1c2zI7LYOcGXaLy5/BACUltPAXo0TIZZwXlrKQqt+jSpxBd8riyL//TVuT3b/GHqMtZAiMkPO8exG/appxu9v1VKJ75VtmnxabBaDmm7LOzv8PsvMIlKn8OD4yQ5J1fQ59+ZZmKnf8HZvslY1JKrt8PvUZ9LdO9DKXBfn+oupglEEK0WC2Mlj7l2qPQ247cntG33h0Wzi1559Z85WYdewdDXz7kApU/hwZCSOyaLYhc9bBCxLm9bmdOj0lJCyUQW75V/dgKyK2UQAgxmvugxWe4/hbNfrwOxQF12ex6UI8HoBeiz1yC5Bpv7kcVT+1B9sM1HiP0djh6IfGVOxCes9Kbsw7ArRRuIZqOVOuAcu1hZ8/C+uWjCQkKzWqEPl1d7ub2PobCkbYJHT8Vb6IWEpnfjNjyl9Qf5vueQKHntQmx0qddjuRd+5T3lv7uQebdGyd0/FS8iVqIA9OBWt6q+MgxWvrhLJtHNnv4+sXOn5sK3uedk1aIs6oymp1n4iPPPap5vuEsfyPzWxQQ+YMvIn/gmfPCmYo30AqJLXsOkQXqhVw1TwD1mouRXH9AvSbJnIG5Y+SqfyrAjzcnrZBRHzVWFum22VWx+/8zFGeQzNuNKJ07UdV4k3kQpZBQ3VIkVn+qnLd1YieGvnigKhaxG15ApGGjOt7RLjjPUtg2SiGJ27oQmn2zwsrN71npqfpRz9udR77m9no2H5z/2dq4/2dokVQZlnPtYXZWrLaqwDjWr52aby2GnT5ZxWiTdwhlQybvdPlHFiFkjkSICCEjQBZHGiJCyAiQxZGGiBAyAmRxpCEihIwAWRxpiAghI0AWRxoiQsgIkMWRhogQMgJkcaQhIoSMAFkcaYgIISNAFkcaIkLICJDFkYaIEDICZHGkISKEjABZHGmICCEjQBZHGiJCyAiQxZGGiBAyAmRxpCEihIwAWRxpiAghI0AWRxpCJuQ/FHc5A6AQ2uwAAAAASUVORK5CYII=','1752842322','1752842322','1752842322');

INSERT INTO auth (id,email,password,active) VALUES ('ec80e845-976d-4f0e-beb7-30212e69da61','admin@local.local','BCRYPTED_PASSWORD','1');
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