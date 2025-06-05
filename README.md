# Nomad multi-cloud setup

Nomad cluster setup with no additional software (Consul, Vault, etc). 

## Runbook

### Set up cloud credentials in your terminal
- Copy and paste AWS credentials into terminal (`AWS_ACCESS_KEY_ID`, etc.)
- Log in to Azure to authenticate CLI
  ```
  az login --tenant TENANT_ID
  ```
- Log in to GCP to authenticate CLI
  ```
  gcloud auth application-default login
  ```

### Create Azure resource group
This resource group will contain the compute resources as well as the machine image. It's created _outside_ of the main configuration as running a `terraform destroy` with it in the main config will destroy the group and _all_ resources in it, including the machine image.

```
cd azure-dependencies
terraform apply
```

### Rename example variables file

```
mv variables.hcl.example variables.hcl
```

### Build machine images

```
packer init && packer build -var-file=variables.hcl (aws|azure|gcp)-image.pkr.hcl
```

Copy the image name from the output and paste it into the appropriate field in `variables.hcl`: `aws_ami`, `azure_image_name`, or `gcp_machine_image`.

### Update `variables.hcl`

Update the values in the variables file with cloud project configurations (region, zone, etc.) and optionally instance types and counts.

### Create the infrastructure

```
cd nomad
terraform apply -var-file=variables.hcl
```