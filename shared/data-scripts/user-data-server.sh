#!/bin/bash

set -e

# Redirects output on file
exec > >(sudo tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#-------------------------------------------------------------------------------
# Configure and start servers
#-------------------------------------------------------------------------------

# Paths for configuration files
#-------------------------------------------------------------------------------

echo "Setup configuration PATHS"

CONFIG_DIR=/ops/shared/conf
NOMAD_CONFIG_DIR=/etc/nomad.d

HOME_DIR=ubuntu

# Retrieve certificates
#-------------------------------------------------------------------------------

echo "Create TLS certificate files"

echo "${ca_certificate}"    | base64 -d | zcat > /tmp/agent-ca.pem
echo "${agent_certificate}" | base64 -d | zcat > /tmp/agent.pem
echo "${agent_key}"         | base64 -d | zcat > /tmp/agent-key.pem

sudo cp /tmp/agent-ca.pem $NOMAD_CONFIG_DIR/nomad-agent-ca.pem
sudo cp /tmp/agent.pem $NOMAD_CONFIG_DIR/nomad-agent.pem
sudo cp /tmp/agent-key.pem $NOMAD_CONFIG_DIR/nomad-agent-key.pem

# IP addresses
#-------------------------------------------------------------------------------

echo "Retrieve IP addresses"

# Wait for network
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
    
    # Standard SKU public IPs aren't in the instance metadata but rather in the loadbalancer
    PUBLIC_IP_ADDRESS=$(curl -s -H Metadata:true --noproxy "*" http://169.254.169.254/metadata/loadbalancer?api-version=2020-10-01 | jq -r '.loadbalancer.publicIpAddresses[0].frontendIpAddress')
    ;;
  *)
    echo "CLOUD_ENV: not set"
    ;;
esac

# Environment variables
#-------------------------------------------------------------------------------

echo "Setup Environment variables"

NOMAD_RETRY_JOIN="${retry_join}"

# nomad.hcl variables needed
NOMAD_DATACENTER="${datacenter}"
NOMAD_DOMAIN="${domain}"
NOMAD_NODE_NAME="${nomad_node_name}"
NOMAD_SERVER_COUNT="${server_count}"
NOMAD_ENCRYPTION_KEY="${nomad_encryption_key}"

NOMAD_MANAGEMENT_TOKEN="${nomad_management_token}"

# Configure and start Nomad
#-------------------------------------------------------------------------------

echo "Create Nomad configuration files"

# Copy template into Nomad configuration directory
sudo cp $CONFIG_DIR/nomad-server.hcl $NOMAD_CONFIG_DIR/nomad.hcl

# Populate the file with values from the variables
sudo sed -i "s/_NOMAD_DATACENTER/$NOMAD_DATACENTER/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_DOMAIN/$NOMAD_DOMAIN/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_NODE_NAME/$NOMAD_NODE_NAME/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_SERVER_COUNT/$NOMAD_SERVER_COUNT/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s#_NOMAD_ENCRYPTION_KEY#$NOMAD_ENCRYPTION_KEY#g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_NOMAD_RETRY_JOIN/$NOMAD_RETRY_JOIN/g" $NOMAD_CONFIG_DIR/nomad.hcl
sudo sed -i "s/_PUBLIC_IP_ADDRESS/$PUBLIC_IP_ADDRESS/g" $NOMAD_CONFIG_DIR/nomad.hcl

echo "Start Nomad"

sudo systemctl enable nomad.service
sudo systemctl start nomad.service

## todo instead of sleeping check on status https://developer.hashicorp.com/nomad/api-docs/status
sleep 10

# Bootstrap Nomad
#-------------------------------------------------------------------------------

echo "Bootstrap Nomad"

# Wait for nomad servers to come up and bootstrap nomad ACL
for i in {1..12}; do
    # capture stdout and stderr
    set +e
    sleep 5
    set -x 
    export NOMAD_ADDR="https://localhost:4646"
    export NOMAD_CACERT="$NOMAD_CONFIG_DIR/nomad-agent-ca.pem"

    OUTPUT=$(echo "$NOMAD_MANAGEMENT_TOKEN" | nomad acl bootstrap - 2>&1)
    if [ $? -ne 0 ]; then
        echo "nomad acl bootstrap: $OUTPUT"
        if [[ "$OUTPUT" = *"No cluster leader"* ]]; then
            echo "nomad no cluster leader"
            continue
        else
            echo "nomad already bootstrapped"
            exit 0
        fi
    else 
        echo "nomad bootstrapped"
        break
    fi
    set +x 
    set -e
done

## todo instead of sleeping check on status https://developer.hashicorp.com/nomad/api-docs/status
sleep 30