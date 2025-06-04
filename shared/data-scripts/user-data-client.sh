#!/bin/bash

set -e

exec > >(sudo tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#-------------------------------------------------------------------------------
# Configure and start clients
#-------------------------------------------------------------------------------

# Paths for configuration files
#-------------------------------------------------------------------------------

CONFIG_DIR=/ops/shared/conf

CONSUL_CONFIG_DIR=/etc/consul.d
VAULT_CONFIG_DIR=/etc/vault.d
NOMAD_CONFIG_DIR=/etc/nomad.d
CONSULTEMPLATE_CONFIG_DIR=/etc/consul-template.d

HOME_DIR=ubuntu

# Retrieve certificates
#-------------------------------------------------------------------------------

echo "${ca_certificate}"    | base64 -d | zcat > /tmp/agent-ca.pem
echo "${agent_certificate}" | base64 -d | zcat > /tmp/agent.pem
echo "${agent_key}"         | base64 -d | zcat > /tmp/agent-key.pem

# Consul clients do not need certificates because auto_tls generates them automatically.
sudo cp /tmp/agent-ca.pem $CONSUL_CONFIG_DIR/consul-agent-ca.pem

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
    PUBLIC_IP_ADDRESS=$(curl -s -H Metadata:true --noproxy "*" http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0?api-version=2021-12-13 | jq -r '.["publicIpAddress"]')
    ;;
  *)
    echo "CLOUD_ENV: not set"
    ;;
esac

# Environment variables
#-------------------------------------------------------------------------------

CONSUL_RETRY_JOIN="${retry_join}"

# nomad.hcl variables needed
NOMAD_DATACENTER="${datacenter}"
NOMAD_DOMAIN="${domain}"
NOMAD_NODE_NAME="${nomad_node_name}"
NOMAD_AGENT_META='${nomad_agent_meta}'


# Install Nomad prerequisites
#-------------------------------------------------------------------------------

# Install and link CNI Plugins to support Consul Connect-Enabled jobs

# export ARCH_CNI=$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)
# export CNI_PLUGIN_VERSION=v1.5.1
# curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGIN_VERSION/cni-plugins-linux-$ARCH_CNI-$CNI_PLUGIN_VERSION".tgz && \
#   sudo mkdir -p /opt/cni/bin && \
#   sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

# export CONSUL_CNI_PLUGIN_VERSION=1.5.1
# curl -L -o consul-cni.zip "https://releases.hashicorp.com/consul-cni/$CONSUL_CNI_PLUGIN_VERSION/consul-cni_"$CONSUL_CNI_PLUGIN_VERSION"_linux_$ARCH_CNI".zip && \
#   sudo unzip consul-cni.zip -d /opt/cni/bin -x LICENSE.txt

# Configure and start Nomad
#-------------------------------------------------------------------------------

# Copy template into Nomad configuration directory
sudo cp $CONFIG_DIR/nomad-client.hcl $NOMAD_CONFIG_DIR/nomad.hcl

set -x 

# Replace [,] with [","] in the list of IPs to correctly format
# them for the retry_join attribute
TEMP_RETRY_JOIN_FILE=$NOMAD_CONFIG_DIR/temp-retry-join-list
echo $CONSUL_RETRY_JOIN > $TEMP_RETRY_JOIN_FILE
sudo sed -i 's|,|","|g' $TEMP_RETRY_JOIN_FILE

# Populate the file with values from the variables
sudo sed -i "s/_NOMAD_DATACENTER/$NOMAD_DATACENTER/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_DOMAIN/$NOMAD_DOMAIN/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_NODE_NAME/$NOMAD_NODE_NAME/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_AGENT_META/$NOMAD_AGENT_META/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_CONSUL_RETRY_JOIN/$(cat $TEMP_RETRY_JOIN_FILE)/g" $NOMAD_CONFIG_DIR/nomad.hcl
# sudo sed -i "s/_CONSUL_AGENT_TOKEN/$NOMAD_AGENT_TOKEN/g" $NOMAD_CONFIG_DIR/nomad.hcl

sudo sed -i "s/_PUBLIC_IP_ADDRESS/$PUBLIC_IP_ADDRESS/g" $NOMAD_CONFIG_DIR/nomad.hcl

set +x 

sudo systemctl enable nomad.service
sudo systemctl start nomad.service