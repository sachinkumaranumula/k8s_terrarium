# What is this for?
Terrarium that bootstraps a k8s cluster to start messing with


# Why was this needed?
When you start diving into k8s components everyone on the public web will send you to the Managed Public Cloud Services(GKE, EKS, AKS, IKS...) or set you up with a cloud provider CLI to provision all the cloud resources needed for k8s. If you are like me and dont want the managed route because you like a good slice of tech inside out and that the CLI does not feel right way to go about it and want to quickly bring things up but more importantly tear them down to keep costs down then this terrarium is for you.


# How do I get going?
Pick the cloud provider from `terraform` directory and get going.
> :info: Google Cloud is the only provider right now and has been picked as a tribute to them for giving us Borg/K8s


## gCloud
- Create [Google Cloud project](https://developers.google.com/workspace/guides/create-project) (e.g. k8s-training-xxxxxx)
- Create [Service Account for terraform](https://cloud.google.com/iam/docs/keys-create-delete) and land it under credentials directory
```bash
gcloud auth login
gcloud config set project k8s-training-xxxxxx
```


## Bootstrap w/ Terraform
- Copy `helpers/gcloud-setup.sh` as `helpers/gcloud-setup.local.sh` and input your values
```bash
source helpers/gcloud-setup.local.sh
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```


## K8s nodes access
> :warning: **Bastion was tried**: there were issues with Bastion + IAP to connect to network as same user, but why do we need bastion when IAP implements a zero-trust access model. One less bastion-vm
```bash
gcloud compute ssh <vm_name> --internal-ip
```
*Or use Desktop IAP* (ease of use)


## Setup k8s cluster
### On every node
- `su - k8s_contrib`, passwd k8s4ever
- Optional : Update _IP addresses_ in `sudo vi /etc/hosts` from terraform output if you want to DNS your own
- To install kube binaries run `sudo sh /bin/k8s-node-setup.sh`

### On master node
- Initialize kube cluster `sh /bin/k8s-admin-init.sh` (copy the kubeadm join command)
- To verify Control Plane node setup run `sudo sh /bin/k8s-node-verify.sh`

### On worker nodes
- Copy output from master *sudo kubeadm init* as  `sudo kubeadm join ...` to join the cluster
- To verify Worker node setup run `sudo sh /bin/k8s-node-verify.sh`


## Finish
- Check cluster health now by running `kubectl get nodes` on *master node* (should look like below)
```bash
NAME       STATUS   ROLES           AGE     VERSION
master-1   Ready    control-plane   4m15s   v1.28.2
worker-1   Ready    <none>          2m12s   v1.28.2
```

## Next Steps
- the nodes are setup with `.vimrc` to work with yaml (all k8s descriptors)
- for bash completions do `sh /bin/k8s-bash-setup.sh`
- for *helm* run `sh /bin/k8s-helm-setup.sh`