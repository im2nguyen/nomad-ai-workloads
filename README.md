# Nomad multi-cloud setup

Nomad cluster setup with no additional software (Consul, Vault, etc) and no VM image building. This setup is done completely with Terraform.

## Runbook

### Set up cloud credentials in your terminal
- Copy and paste AWS credentials into terminal (`AWS_ACCESS_KEY_ID`, etc.)

### Rename example variables file

```
cd ../nomad
mv variables.hcl.example variables.hcl
```

### Update `variables.hcl`

Update the values in the variables file with cloud project configurations (region, zone, etc.) and optionally instance types and counts.

### Create the infrastructure

```
terraform apply -var-file=variables.hcl
```