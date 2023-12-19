#cloud-config
write_files:
  - path: /bin/k8s-admin-kubectl-config-setup.sh
    permissions: "0774"
    content: |
      #!/bin/bash 
      sudo mkdir -p $HOME/.kube
      sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown -R $(id -u):$(id -g) $HOME/.kube
  - path: /bin/k8s-admin-init.sh
    permissions: "0774"
    content: |
      #!/bin/bash 
      sudo kubeadm init
      #Alternative to below if you are root then just export KUBECONFIG=/etc/kubernetes/admin.conf
      sh /bin/k8s-admin-kubectl-config-setup.sh
      kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
  - path: /bin/k8s-helm-setup.sh
    permissions: "0774"
    content: |
      #!/bin/bash 
      wget https://get.helm.sh/helm-v3.13.2-linux-amd64.tar.gz  
      tar -xvf helm-v3.13.2-linux-amd64.tar.gz
      sudo cp linux-amd64/helm /usr/local/bin/helm

# Run a few commands (update apt's repo indexes and install curl)
runcmd:
  - chown k8s_contrib:k8s_admin /bin/k8s-admin-init.sh /bin/k8s-admin-kubectl-config-setup.sh /bin/k8s-helm-setup.sh