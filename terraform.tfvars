#-----------------------------------------------------------------------------------------------------
# Paster your credentials here
# AWS access key used to create infrastructure
# aws_access_key = ""

# # AWS secret key used to create AWS infrastructure
# aws_secret_key = ""

# # AWS session token used to create AWS infrastructure
# aws_session_token = ""
#-----------------------------------------------------------------------------------------------------
# just a tag
creator = "nick"

# Prefix added to names of all resources
prefix = "present"

# Admin password to use for Rancher server bootstrap, min. 12 characters
rancher_server_admin_password = "123456789.Rancher"

# AWS region used for all resources
aws_region = "us-east-2"

# AWS zone used for all resources
aws_zone = "us-east-2a"

# Version of cert-manager to install alongside Rancher (format: 0.0.0)
cert_manager_version = "1.12.3"

# Instance type used for all EC2 instances
instance_type = "t3a.large"

# The helm repository, where the Rancher helm chart is installed from
rancher_helm_repository = "https://releases.rancher.com/server-charts/stable"

# Kubernetes version to use for Rancher server cluster
rancher_kubernetes_version = "v1.25.9+k3s1"

# Rancher server version (format: v0.0.0)
rancher_version = "2.7.5"
