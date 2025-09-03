#-------------------------------------------------------------------------------
# Instance Outputs
#-------------------------------------------------------------------------------

output "instances" {
  description = "List of all created instances"
  value       = aws_instance.nomad_clients
}

output "instance_ids" {
  description = "List of all instance IDs"
  value       = [for instance in aws_instance.nomad_clients : instance.id]
}

output "instance_public_ips" {
  description = "List of public IP addresses"
  value       = [for instance in aws_instance.nomad_clients : instance.public_ip]
}

output "instance_private_ips" {
  description = "List of private IP addresses"
  value       = [for instance in aws_instance.nomad_clients : instance.private_ip]
}

#-------------------------------------------------------------------------------
# Configuration Outputs
#-------------------------------------------------------------------------------

output "size" {
  description = "Size of the client instances"
  value       = var.size
}

output "public" {
  description = "Whether the clients are public"
  value       = var.public
}

output "count" {
  description = "Number of instances created"
  value       = var.count
}

#-------------------------------------------------------------------------------
# Summary Outputs
#-------------------------------------------------------------------------------

output "total_instances" {
  description = "Total number of instances created"
  value       = length(aws_instance.nomad_clients)
}

output "instance_summary" {
  description = "Summary of instances"
  value = {
    size   = var.size
    public = var.public
    count  = var.count
    instances = [
      for i, instance in aws_instance.nomad_clients : {
        id         = instance.id
        public_ip  = instance.public_ip
        private_ip = instance.private_ip
        name       = "${var.prefix}-${var.size}-${var.public ? "public" : "private"}-client-${i}"
      }
    ]
  }
}
