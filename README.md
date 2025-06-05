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
This resource group will contain the compute resources as well as the machine image. Creating it outside of the main config allows the infrastructure to be created and destroyed without deleting the machine image, which is saved in the resource group.

```
cd azure-dependencies
terraform apply
```

### Rename example variables file

```
cd nomad
mv variables.hcl.example variables.hcl
```

### Build machine images

Run for each cloud environment: `aws`, `azure`, and `gcp`.

```
packer init (aws|azure|gcp)-image.pkr.hcl
packer build -var-file=variables.hcl (aws|azure|gcp)-image.pkr.hcl
```

Copy the image name from the output and paste it into the appropriate field in `variables.hcl`: `aws_ami`, `azure_image_name`, and `gcp_machine_image`.

### Update `variables.hcl`

Update the values in the variables file with cloud project configurations (region, zone, etc.) and optionally instance types and counts.

### Create the infrastructure

```
terraform apply -var-file=variables.hcl
```