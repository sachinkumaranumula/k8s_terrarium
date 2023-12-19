#cloud-config
write_files:
  - path: /bin/k8s-bash-setup.sh
    permissions: "0774"
    content: |
      source <(kubectl completion bash) # set up autocomplete in bash into the current shell, bash-completion package should be installed first.
      echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
      alias k=kubectl
      complete -o default -F __start_kubectl k
  - path: /bin/k8s-cri-setup.sh
    permissions: "0774"
    content: |
      #### CONTAINERD ####
      echo "BEGIN: INSTALLING CONTAINERD"
      for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove $pkg; done
      install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      chmod a+r /etc/apt/keyrings/docker.gpg
      echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
      apt-get update
      apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      mkdir -p /etc/containerd
      containerd config default>/etc/containerd/config.toml
      # cgroup driver same as docker
      cat <<EOF | sudo tee /etc/docker/daemon.json
      {
        "exec-opts": ["native.cgroupdriver=systemd"],
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "100m"
        },
        "storage-driver": "overlay2"
      }
      EOF
      systemctl daemon-reload && sudo systemctl restart docker
      systemctl restart containerd
      systemctl enable containerd
      echo "END: INSTALLING CONTAINERD"
  - path: /etc/crictl.yaml
    permissions: "0644"
    content: | 
      runtime-endpoint: unix:///var/run/containerd/containerd.sock
      image-endpoint: unix:///var/run/containerd/containerd.sock
      timeout: 10
      debug: true
  - path: /bin/k8s-tools-setup.sh
    permissions: "0774"
    content: |
      #### KUBEADM, KUBECTL, KUBELET ####
      echo "BEGIN: INSTALLING KUBEADM, KUBECTL, KUBELET"
      # You MUST disable swap in order for the kubelet to work properly.
      swapoff -a
      # Kernel Settings 
      cat <<EOF | tee /etc/modules-load.d/k8s.conf
      overlay
      br_netfilter
      EOF
      modprobe overlay
      modprobe br_netfilter
      # sysctl settings
      cat << EOF | tee /etc/sysctl.d/kubernetes.conf
      net.bridge.bridge-nf-call-ip6tables = 1
      net.bridge.bridge-nf-call-iptables = 1
      net.ipv4.ip_forward = 1
      EOF
      # Reload sysctlt
      sysctl --system
      # Download public signing key
      curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --yes --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
      # Add k8s repositories
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
      # Install (lays down 1.28)
      apt-get update
      apt -y install -y kubeadm kubelet kubectl
      apt-mark hold kubelet kubeadm kubectl
      systemctl enable --now kubelet
      echo "END: INSTALLING KUBEADM, KUBECTL, KUBELET"
  - path: /bin/k8s-node-setup.sh
    permissions: "0774"
    content: |
      #### UDPATE/UPGRADE ####
      apt-get update && apt-get upgrade -y
      apt-get install -y apt-transport-https ca-certificates curl gpg
      sh /bin/k8s-cri-setup.sh
      sh /bin/k8s-tools-setup.sh
  - path: /bin/k8s-node-verify.sh
    permissions: "0774"
    content: |
      lsmod | grep br_netfilter
      lsmod | grep overlay
      sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
      systemctl status docker --no-pager
      systemctl status containerd --no-pager
      systemctl status kubelet --no-pager

# Run a few commands (update apt's repo indexes and install curl)
runcmd:
  - chown k8s_contrib:k8s_admin /bin/k8s-cri-setup.sh /bin/k8s-tools-setup.sh /bin/k8s-node-setup.sh /bin/k8s-node-verify.sh /bin/k8s-bash-setup.sh
