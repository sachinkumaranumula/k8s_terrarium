> While the [cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) gives a good soak, this will get good some laps going

# Big Picture

## Entities

- operators(endpoint, service, namespace, serviceaccounts) - DeltaFIFO queue (Informer & Workqueue)
  - service (connect pods, expose pods to internet, decouple settings, access policy)
  - namespace (default, kube-node-lease, kube-public, kube-system)
- api objects
  - deployments
  - pod (one process per container, parallel starts, init container for order) - 1 IP address
  - replica set
  - daemon sets
  - stateful sets
  - service account
  - roles
  - ...
- quotas
  - podspec
  - resourcequota (namespace)
- rbac
  - ClusterRole, Role, ClusterRoleBinding, RoleBinding

## Abstractions

- Single IP per Pod
  - Intra Container Communication: Pause Container grabs an IP all containers in pod share same network namespace and they use loopback or IPC for comm
  - Outside Pod: Ephemeral Pod IP -> Endpoint (Pod IP: Port, kubelet/kproxy provided) -> Service (Cluster IP(CNI provided) + NodePort (high port of node))
- Services
  - ClusterIP (default internal)
  - NodePort (port range for firewall)
  - LoadBalancer (cloud provider)
  - ExternalName (DNS level, alias to external)

## Flow

- Simple Deployment (API Call flow)
  - flow of access to a cluster begins with TLS connectivity, then authentication followed byauthorization, finally an admission control plug-in allows advanced features prior to the request being fulfilled
  - kubectl -> API Server -> ETCD
  - Controller Manager (state check) -> API Server -> ETCD
  - Controller Manger (desired state) -> API Server (create deploy then rs and pod) to reach desired state
    - API Server -> Scheduler (schedule pod to worker nodes)
    - API Server -> Kubelet of scheduled pod worker nodes
    - API Server -> Kubeproxy of all cluster nodes to be aware of new state changes
    - Kubelet -> gets all resources of Pod Spec
    - Kubelet -> docker engine create new containers
    - Docker Engine -> Kubelet -> Kube API Server -> ETCD of pods now created

# All Actions

- Anatomy
  - `kubectl [command] [type] [Name] [flag]`
- Context
  - `kubectl config get-contexts`
- View CPU, memory, resource usage, requests an limits
  - `kubectl describe node`
- Removing node from cluster
  - ` kubectl delete node <node-name>` and then `kubeadm reset`
- Template deployment yaml
  - `kubectl get deployment nginx -o yaml > first.yaml`
  - `kubectl create deployment two --image=nginx --dry-run=client -o yaml`
- Non Disruptive Update
  - `kubectl edit/apply/patch`
- Disruptive Update
  - `kubectl replace -f first.yaml --force`
- Expose Service
  - `kubectl expose deployment/nginx`
  - `kubectl expose deployment nginx --type=LoadBalancer`
  - `kubectl expose deployment/nginx --port=80 --type=NodePort`
  - `kubectl -n accounting describe services`
  - `kubectl -n kube-system get svc`
- Scale
  - `kubectl scale deployment nginx --replicas=3`
- Interactive Pod
  - `kubectl run -i -t busybox --image=busybox --restart=Never`
- Run on Pod
  - `kubectl exec <pod> -- printenv |grep KUBERNETES`
  - `kubectl exec shell-demo -- /bin/bash -c'df -ha |grep car'`
- CRUD on API Objects
  - `kubectl get <entity_type>`
  - `kubectl create <entity_type> <entity_name>`
  - `kubectl describe <entity_type> <entity_name>`
  - `kubectl get <entity_type>/<entity_name> -o yaml`
  - `kubectl delete <entity_type>/<entity_name>`
- Rollbacks
  - `kubectl rollout undo deployment/ghost` or `kubectl rollout undo ds ds-one --to-revision=1`
  - `kubectl rollout pause deployment/ghost`
  - `kubectl rollout resume deployment/ghost`
  - `kubectl rollout history deploy webserver`
- Labels/Taints
  - `kubectl get pods --show-labels`
  - `kubectl get pods -L run`
  - `kubectl delete pod -l system=IsolatedPod`
  - `kubectl describe nodes | grep Labels`
  - `kubectl describe nodes | grep Taints`
  - `sudo crictl ps`
  - `kubectl label nodes cp status=vip`
  - `kubectl get nodes --show-labels`
  - `kubectl taint node worker bubba=value:PreferNoSchedule`
  - `kubectl describe nodes | grep -i taint`
  - `kubectl taint node cp bubba-`
- Logs
  - `kubectl logs <pod>`
- Trace
  - `sudo apt-get install -y strace`
  - `strace kubectl get endpoints`
- Volume
  - `kubectl create -f PVol.yaml`
  - `kubectl create -f pvc.yaml`
  - `kubectl get pv pvc`
  - `kubectl -n small create -f storage-quota.yaml`
  - `kubectl describe ns small`
  - On Master
    - `sudo apt-get update && sudo apt-get install -y nfs-kernel-server`
    - `sudo vim /etc/exports #/opt/sfw/ \*(rw,sync,no_root_squash,subtree_check)`
    - `sudo exportfs -ra`
  - On Woker -`sudo apt-get -y install nfs-common` -`showmount -e k8scp` -`sudo mount k8scp:/opt/sfw /mnt`
- Passing Data to Pod
  - Secret
    - `kubectl create secret generic mysql --from-literal=password=root`
    - `echo LFTr@1n | base64`
  - Config Map
    - `kubectl create configmap colors --from-literal=text=black  --from-file=./favorite  --from-file=./primary/`
    - `kubectl get configmap colors`
- Lower Level
  - Secure API access
    - `export client=$(grep client-cert $HOME/.kube/config |cut -d" " -f 6)`
    - `export key=$(grep client-key-data $HOME/.kube/config |cut -d " " -f 6)`
    - `export auth=$(grep certificate-authority-data $HOME/.kube/config |cut -d " " -f 6)`
    - `echo $client | base64 -d - > ./client.pem`
    - `echo $key | base64 -d - > ./client-key.pem`
    - `echo $auth | base64 -d - > ./ca.pem`
    - `kubectl config view |grep server`
    - `curl --cert ./client.pem --key ./client-key.pem --cacert ./ca.pem https://k8scp:6443/api/v1/pods`
  - Insecure API access
    - `export token=$(kubectl create token default)`
    - `curl https://k8scp:6443/apis --header "Authorization: Bearer $token" -k`
  - Proxy access
    - `kubectl proxy --api-prefix=/ &`
- Charts
  - `helm search hub database`
  - `helm repo add bitnami https://charts.bitnami.com/bitnami`
  - `helm search repo bitnami`
  - `helm fetch bitnami/apache --untar`
  - `helm install my-release bitnami/<chart>`
  - `helm search hub ingress`
  - `helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace kube-system`
  - `helm repo update`
  - `helm upgrade -i tester ealenn/echo-server --debug`
  - `helm list`
  - `helm uninstall tester`
- CRD
  - `kubectl get crd --all-namespaces`
  - `kubectl create -f crd.yaml`
  - `kubectl get crd`
  - `kubectl describe crd crontab<Tab>`
  - `kubectl create -f new-crontab.yaml`
  - `kubectl get CronTab`
  - `kubectl get ct`
  - `kubectl describe ct`
  - `kubectl delete -f crd.yaml`
  - `kubectl get ct`

# Admin

- Cluster
  - `kubectl config view`
  - `sudo kubeadm config print init-defaults`
- Logs/Monitoring
  - `journalctl -u kubelet |less`
  - `sudo find / -name "*apiserver*log"`
  - `kubectl -n kube-system logs kube-apiserver-cp`
  - `kubectl get po --all-namespaces`
- Manifests
  - `/etc/kubernetes/manifests/` - where every pod resides and kubelet runs them
- Upgrade
  - `kubeadm upgrade plan` - critical upgrade plan
- Etcd
  - `etcdctl snapshot save/restore` - etcd - B+ tree kv store
  - `sudo grep data-dir /etc/kubernetes/manifests/etcd.yaml`
  - Backup
    - `cp $HOME/.kube/config $HOME/cluster-api-config`
    - `kubectl -n kube-system exec -it etcd-<Tab> -- sh`
    - `cd /etc/kubernetes/pki/etcd`
    - `kubectl -n kube-system exec -it etcd-cp -- sh -c "ETCDCTL_API=3 ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key etcdctl endpoint health"`
    - same as above `--endpoints=https://127.0.0.1:2379 member list -w table`
    - same as above `--endpoints=https://127.0.0.1:2379 snapshot save /var/lib/etcd/snapshot.db`
    - `sudo cp /var/lib/etcd/snapshot.db, /root/kubeadm-config.yaml, -r /etc/kubernetes/pki/etcd`
- Cluster Upgrade
  - `sudo apt update`
  - `sudo apt-cache madison kubeadm`
  - `sudo apt-mark unhold kubeadm`
  - `sudo apt-get install -y kubeadm=1.28.1-00`
  - `sudo apt-mark hold kubeadm`
  - `kubectl drain cp --ignore-daemonsets`
  - `sudo kubeadm upgrade plan`
  - `sudo kubeadm upgrade apply v1.28.1` on cp and `sudo kubeadm upgrade node` on worker
  - `sudo apt-mark unhold kubelet kubectl`
  - `sudo apt-get install -y kubelet=1.28.1-00 kubectl=1.28.1-00`
  - `sudo apt-mark hold kubelet kubectl`
  - `sudo systemctl daemon-reload`
  - `sudo systemctl restart kubelet`
  - `kubectl uncordon cp`
- Network
  - `calicoctl` - network
- AuthZ
  - `kubectl auth can-i create deployments`
- Metadata
  - `kubectl annotate pods --all description='Production Pods' -n prod`
  - `kubectl -n prod annotate pod webpod description-`
- Verbose
  - `kubectl --v=10 get pods firstpod`
- Top
  - `kubectl top <pod/nodes>`
- Containers
  - ` sudo crictl ps`
- Ingress Controller
  - `helm search hub ingress --list-repo-url | grep nginx`
  - `helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx`
  - `helm repo list`
  - `helm fetch ingress-nginx/ingress-nginx --untar`
  - cd ingress-nginx, vim values.yaml and change to DaemonSet instead of Deployment (want it on every node)
  - `helm install myingress .`
  - `curl -H "Host: www.external.com" <ingress controller svc ip address>`
- Rolling Updates and Rollback
  - `kubectl get ds ds-one -o yaml | grep -A 4 Strategy`
  - `kubectl edit ds ds-one`
  - `kubectl set image ds ds-one nginx=nginx:1.16.1-alpine`
  - `kubectl rollout history ds ds-one`
  - `kubectl rollout history ds ds-one --revision=1`
  - `kubectl rollout undo ds ds-one --to-revision=1`
  - `kubectl edit ds ds-two --record`
  - `kubectl rollout status ds ds-two`
  - `kubectl rollout history ds ds-two`
  - `kubectl rollout history ds ds-two --revision=2`
- Security
  - `systemctl status kubelet.service`
  - `kubectl -n kube-system get secrets`
  - `kubectl config view`
  - `sudo kubeadm config print init-defaults`
  - `kubectl create ns development`
  - `kubectl create ns production`
  - `sudo useradd -s /bin/bash DevDan`
  - `sudo passwd DevDan`
  - `openssl genrsa -out DevDan.key 2048`
  - `openssl req -new -key DevDan.key -out DevDan.csr -subj "/CN=DevDan/O=development"`
  - `sudo openssl x509 -req -in DevDan.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out DevDan.crt -days 45`
  - `kubectl config set-credentials DevDan --client-certificate=/home/gcp-contrib/DevDan.crt --client-key=/home/gcp-contrib/DevDan.key`
  - `kubectl config set-context DevDan-context --cluster=kubernetes --namespace=development --user=DevDan`
  - `kubectl --context=DevDan-context create deployment nginx --image=nginx`
  - `kubectl --context=DevDan-context get pods`
  - `kubectl --context=DevDan-context delete deploy nginx`
  - `kubectl config set-context ProdDan-context --cluster=kubernetes --namespace=production --user=DevDan`
  - `kubectl --context=ProdDan-context create deployment nginx --image=nginx`
  - `kubectl -n production describe role dev-prod`
  - `sudo grep admission /etc/kubernetes/manifests/kube-apiserver.yaml`

# Troubleshooting Guide

- Errors from the command line
- Pod logs and state of Pods
  - `kubectl -n kube-system logs <Tab><Tab>`
- Use shell to troubleshoot Pod DNS and network
- Check node logs for errors, make sure there are enough resources allocated
  - `journalctl -u kubelet |less`
- RBAC, SELinux or AppArmor for security settings​
- API calls to and from controllers to kube-apiserver
  - `sudo find / -name "*apiserver*log"`
- Enable auditing
- Inter-node network issues, DNS and firewall
- Control Plane server controllers (control Pods in pending or error state, errors in log files, sufficient resources, etc).
- Tools
  - `kubectl debug buggypod --image debian --attach` (attach)
  - `kubectl debug -it ephemeral-demo --image=busybox:1.28 --target=ephemeral-demo`

# Unix

- Install Software
  - `sudo apt-get update ; sudo apt-get install -y haproxy vim`
- File commands
  - `diff first.yaml second.yaml`
- TCP
  - `tcpdump`
- Disk
  - `sudo dd if=/dev/zero of=/opt/sfw/bigfile bs=1M count=300`
- IP Address
  - `curl ifconfig.io`
  - `ip a`
  - `hostname -i`
- Subfiles
  - `find .`
- Json
  - `python3 -m json.tool /.kube/cache/discovery/v1/serverresources.json`
- Network
  - `nc` - send or receive traffic
  - `dig @10.96.0.10 -x 10.96.0.10` - get info about name servers
  - `nslookup -q=A example.com` - query DNS
- SSL
  - `sudo useradd -s /bin/bash DevDan`
  - `sudo passwd DevDan`
  - `openssl genrsa -out DevDan.key 2048` (private key)
  - `openssl req -new -key DevDan.key -out DevDan.csr -subj "/CN=DevDan/O=development"` (CSR)
  - `sudo openssl x509 -req -in DevDan.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out DevDan.crt -days 4` (x509 self signed certificate)
  - `kubectl config set-credentials DevDan --client-certificate=DevDan.crt --client-key=DevDan.key` (add user to config)
  - `kubectl config set-context DevDan-context --cluster=kubernetes --namespace=development --user=DevDan` (context for new user)
  - Create role and role binding to verbs on api resources
