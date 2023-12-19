# Bootstrap a simple k8s cluster
Terrarium that bootstraps a k8s cluster to start messing with

# Terraform
```console
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

## gCloud
- Create [Google Cloud project](https://developers.google.com/workspace/guides/create-project) 
- Create [service account for terraform](https://cloud.google.com/iam/docs/keys-create-delete) and land it under credentials directory
- Copy `helpers/gcloud-setup.sh` as `helpers/gcloud-setup.local.sh` and input your values
```bash
source helpers/gcloud-setup.local.sh
gcloud auth login
gcloud config set project k8s-training-xxxxxx
```

> :warning: **Bastion was tried**: there were issues with Bastion + IAP to connect to network as same user, but why do we need bastion when IAP implements a zero-trust access model. One less bastion-vm

## K8s nodes access
```bash
gcloud compute ssh <vm_name> --internal-ip
```
*Or use Desktop IAP* 

*Or other options*
```bash
gcloud compute ssh bastion-vm --ssh-flag="-A" --command "ssh vm-k8s-dev-001" -- -t
gcloud compute ssh "[user]@[instance]" --ssh-flag="-o PubkeyAcceptedKeyTypes=+ssh-rsa"
gcloud compute ssh vm-k8s-dev-001 --project=k8s-training-xxxxxx --zone=us-central1-c --troubleshoot --tunnel-through-iap
```

## On every node
- `su - k8s_contrib`, passwd k8s4ever
- Optional : Update _IP addresses_ in `sudo vi /etc/hosts` from terraform output if you want to DNS your own
- To install kube binaries run `sudo sh /bin/k8s-node-setup.sh`

## On master node
- Initialize kube cluster `sh /bin/k8s-admin-init.sh` (copy the kubeadm join command)
- To verify Control Plane node setup run `sudo sh /bin/k8s-node-verify.sh`

## On worker nodes
- Copy output from master *sudo kubeadm init* as  `sudo kubeadm join ...` to join the cluster
- To verify Worker node setup run `sudo sh /bin/k8s-node-verify.sh`

## Finish
- Check cluster health now by running `kubectl get nodes` on *master node* (should look like below)
```bash
NAME       STATUS   ROLES           AGE     VERSION
master-1   Ready    control-plane   4m15s   v1.28.2
worker-1   Ready    <none>          2m12s   v1.28.2
```

## Tips
- Use `sh /bin/k8s-bash-setup.sh` to setup bash for kubectl