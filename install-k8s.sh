#! /bin/bash
{
[[ ${DEBUG} == "on" ]] && { set -x; }
[[ ${HOME} == "" ]] && { export HOME=$(grep '^root' /etc/passwd | awk -F':' '{print $6 }'); }
set -e

RELEASE=$(cat /etc/os-release | grep -i '^ID='  | awk -F'=' '{print $2}' | tr -d '"')
VERSION=$(cat /etc/os-release | grep -i '^VERSION_ID='  | awk -F'=' '{print $2}' | tr -d '"')

prepareRequisite() {
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
    sudo sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    sudo sysctl --system
}


initK8s() {
    sudo systemctl enable --now kubelet
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet

    sudo rm -rf /etc/kubernetes /var/lib/etcd /root/.kube/

    iface=`ip route show | grep default | awk '{print $5}'`
    outip=`ip -4 a s $iface | grep inet |  awk -F"/"  '{print $1;}' | awk '{print $2}'`

    sudo kubeadm init --node-name=$outip --pod-network-cidr=10.244.0.0/16

    sudo mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    sudo kubectl taint node $(kubectl get node -l node-role.kubernetes.io/master | grep -v NAME | awk '{print $1}') 'node-role.kubernetes.io/master'-
}

ubuntuInstall() {
    sudo apt-get update && sudo apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl

    initK8s
}

installCentosCommonK8s() {
    # Set SELinux in permissive mode (effectively disabling it)
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

    sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

    initK8s
}

installCentos7K8s() {
    installCentosCommonK8s
}

installCentos8K8s() {
    installCentosCommonK8s
}

installCentosK8s() {
    case $VERSION in
    7)
        installCentos7K8s
    ;;
    8)
        installCentos8K8s
    ;;
    esac
}

check() {
    sudo docker run --rm \
    --net host \
    -v /etc/kubernetes:/etc/kubernetes k8s.gcr.io/etcd:3.4.3-0 etcdctl \
    --cert /etc/kubernetes/pki/etcd/peer.crt \
    --key /etc/kubernetes/pki/etcd/peer.key \
    --cacert /etc/kubernetes/pki/etcd/ca.crt \
    --endpoints https://127.0.0.1:2379 endpoint health --cluster

    sudo kubectl get pods -A -owide
}

updateNetwork() {
    while kubectl api-versions >/devnull ; ret=$? ; [ $ret -ne 0 ];do
       echo "wait kubernetes provisoning"
       sleep 2
    done
    sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
}

checkExist() {
    sudo kubectl api-versions >/devnull ; ret=$? ;
    [ $ret -eq 0 ] && {
        echo "k8s already exists"
    }
}


main() {
    [[ ${FORCE} == "on" ]] && {
        sudo systemctl stop kubelet docker || true
        sudo kubeadm reset -f || true
        sudo systemctl start kubelet docker || true
    }
    prepareRequisite
    case $RELEASE in
        ubuntu)
            ubuntuInstall
        ;;
        centos)
            installCentosK8s
        ;;
    esac
    updateNetwork
    check
}

main
}