export CLOUDSDK_COMPUTE_REGION=us-central1
export CLOUDSDK_COMPUTE_ZONE=us-central1-c
export CLOUDSDK_CORE_PROJECT=k8s-training-376016
export TF_VAR_project=k8s-training-376016
export TF_VAR_credentials_file="credentials/k8s-training-sa-credentials.json"
# Your personal accounts this will also be the same user that will use IAP and have user account on provisioned machines
export TF_VAR_members="[\"user:sachinkumaranumula@thewhitepeacock.llc\"]"