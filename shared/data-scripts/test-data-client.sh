#!/bin/bash

# --- BEGIN SETUP.SH --- #

set -e

# Disable interactive apt prompts
export DEBIAN_FRONTEND="noninteractive"

mkdir -p /ops/shared/conf

CONFIGDIR=/ops/shared/conf
NOMADVERSION=1.10.1

sudo apt-get update && sudo apt-get install -y software-properties-common

sudo add-apt-repository universe && sudo apt-get update
sudo apt-get install -y unzip tree redis-tools jq curl tmux
sudo apt-get clean


# Disable the firewall

sudo ufw disable || echo "ufw not installed"

# Docker
# distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
sudo apt-get install -y apt-transport-https ca-certificates gnupg2

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update
sudo apt-get install -y docker-ce

# Java
sudo add-apt-repository -y ppa:openjdk-r/ppa
sudo apt-get update 
sudo apt-get install -y openjdk-8-jdk
JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")


# Install HashiCorp Apt Repository
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Nomad package
sudo apt-get update && sudo apt-get -y install nomad=$NOMADVERSION*

# --- END SETUP.SH --- #

# exec > >(sudo tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#-------------------------------------------------------------------------------
# Configure and start clients
#-------------------------------------------------------------------------------

# Paths for configuration files
#-------------------------------------------------------------------------------

CONFIG_DIR=/ops/shared/conf
NOMAD_CONFIG_DIR=/etc/nomad.d

HOME_DIR=ubuntu

# Retrieve certificates
#-------------------------------------------------------------------------------

echo "${ca_certificate}"    | base64 -d | zcat > /tmp/agent-ca.pem
echo "${agent_certificate}" | base64 -d | zcat > /tmp/agent.pem
echo "${agent_key}"         | base64 -d | zcat > /tmp/agent-key.pem

sudo cp /tmp/agent-ca.pem $NOMAD_CONFIG_DIR/nomad-agent-ca.pem
sudo cp /tmp/agent.pem $NOMAD_CONFIG_DIR/nomad-agent.pem
sudo cp /tmp/agent-key.pem $NOMAD_CONFIG_DIR/nomad-agent-key.pem

# IP addresses
#-------------------------------------------------------------------------------

# Wait for network
## todo test if this value is not too big
sleep 15

DOCKER_BRIDGE_IP_ADDRESS=`ip -brief addr show docker0 | awk '{print $3}' | awk -F/ '{print $1}'`

CLOUD="${cloud_env}"

# Get IP from metadata service
case $CLOUD in
  aws)
    echo "CLOUD_ENV: aws"
    TOKEN=$(curl -X PUT "http://instance-data/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

    IP_ADDRESS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://instance-data/latest/meta-data/local-ipv4)
    PUBLIC_IP_ADDRESS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://instance-data/latest/meta-data/public-ipv4)
    ;;
  gce)
    echo "CLOUD_ENV: gce"
    IP_ADDRESS=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
    PUBLIC_IP_ADDRESS=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    ;;
  azure)
    echo "CLOUD_ENV: azure"
    IP_ADDRESS=$(curl -s -H Metadata:true --noproxy "*" http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0?api-version=2021-12-13 | jq -r '.["privateIpAddress"]')
    # PUBLIC_IP_ADDRESS=$(curl -s -H Metadata:true --noproxy "*" http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0?api-version=2021-12-13 | jq -r '.["publicIpAddress"]')
    
    # Standard SKU public IPs aren't in the instance metadata but rather in the loadbalancer
    PUBLIC_IP_ADDRESS=$(curl -s -H Metadata:true --noproxy "*" http://169.254.169.254/metadata/loadbalancer?api-version=2020-10-01 | jq -r '.loadbalancer.publicIpAddresses[0].frontendIpAddress')
    ;;
  *)
    echo "CLOUD_ENV: not set"
    ;;
esac

# Environment variables
#-------------------------------------------------------------------------------

NOMAD_RETRY_JOIN="${retry_join}"

# nomad.hcl variables needed
NOMAD_DATACENTER="${datacenter}"
NOMAD_DOMAIN="${domain}"
NOMAD_NODE_NAME="${nomad_node_name}"
NOMAD_AGENT_META='${nomad_agent_meta}'
NOMAD_CLIENT_NODE_POOL=${node_pool}


# Install Nomad prerequisites
#-------------------------------------------------------------------------------

# Install and link CNI Plugins to support Consul Connect-Enabled jobs

export ARCH_CNI=$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)
export CNI_PLUGIN_VERSION=v1.5.1
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGIN_VERSION/cni-plugins-linux-$ARCH_CNI-$CNI_PLUGIN_VERSION".tgz && \
  sudo mkdir -p /opt/cni/bin && \
  sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

# Configure and start Nomad
#-------------------------------------------------------------------------------

# Copy template into Nomad configuration directory
# sudo cp $CONFIG_DIR/nomad-client.hcl $NOMAD_CONFIG_DIR/nomad.hcl

rm -f $NOMAD_CONFIG_DIR/nomad.hcl

# set -x 

# Create nomad agent config file
tee $NOMAD_CONFIG_DIR/nomad.hcl <<EOF
# -----------------------------+
# BASE CONFIG                  |
# -----------------------------+

datacenter = "_NOMAD_DATACENTER"
region = "_NOMAD_DOMAIN"

# Nomad node name
name = "_NOMAD_NODE_NAME"

# Data Persistence
data_dir = "/opt/nomad"

# Logging
log_level = "INFO"
enable_syslog = false
enable_debug = false

# -----------------------------+
# CLIENT CONFIG                |
# -----------------------------+

client {
  enabled = true
  options {
    "driver.raw_exec.enable"    = "1"
    "docker.privileged.enabled" = "true"
  }
  meta {
    _NOMAD_AGENT_META
  }
  server_join {
    retry_join = [ "_NOMAD_RETRY_JOIN" ]
  }
  node_pool = "_NODE_POOL"
}

# -----------------------------+
# NETWORKING CONFIG            |
# -----------------------------+

bind_addr = "0.0.0.0"

advertise {
  http = "_PUBLIC_IP_ADDRESS:4646"
  rpc  = "_PUBLIC_IP_ADDRESS:4647"
  serf = "_PUBLIC_IP_ADDRESS:4648"
}

# TLS Encryption              
# -----------------------------

tls {
  http      = true
  rpc       = true

  ca_file   = "/etc/nomad.d/nomad-agent-ca.pem"
  cert_file = "/etc/nomad.d/nomad-agent.pem"
  key_file  = "/etc/nomad.d/nomad-agent-key.pem"

  verify_server_hostname = true
}

# ACL Configuration              
# -----------------------------

acl {
  enabled = true
}
EOF

# Replace [,] with [","] in the list of IPs to correctly format
# them for the retry_join attribute
TEMP_RETRY_JOIN_FILE=$NOMAD_CONFIG_DIR/temp-retry-join-list
echo $NOMAD_RETRY_JOIN > $TEMP_RETRY_JOIN_FILE
sudo sed -i 's|,|","|g' $TEMP_RETRY_JOIN_FILE

# Populate the file with values from the variables
sudo sed -i "s/_NOMAD_DATACENTER/$NOMAD_DATACENTER/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_DOMAIN/$NOMAD_DOMAIN/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_NODE_NAME/$NOMAD_NODE_NAME/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_AGENT_META/$NOMAD_AGENT_META/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_RETRY_JOIN/$(cat $TEMP_RETRY_JOIN_FILE)/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_PUBLIC_IP_ADDRESS/$PUBLIC_IP_ADDRESS/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NODE_POOL/$NOMAD_CLIENT_NODE_POOL/g" $NOMAD_CONFIG_DIR/nomad.hcl

set +x 

sudo systemctl enable nomad.service
sudo systemctl start nomad.service