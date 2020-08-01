#! /bin/bash
{
[[ ${DEBUG} == "on" ]] && { set -x; }
set -e

RELEASE=$(cat /etc/os-release | grep -i '^ID='  | awk -F'=' '{print $2}' | tr -d '"')
VERSION=$(cat /etc/os-release | grep -i '^VERSION_ID='  | awk -F'=' '{print $2}' | tr -d '"')

ubuntuInstall() {
    sudo apt-get remove docker docker-engine docker.io containerd runc
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

centos7Install() {
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd
    sudo systemctl enable --now docker
}

centos8Install() {
    sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf install -y docker-ce --nobest
}

centosInstall() {
    case $VERSION in
    7)
        centos7Install
    ;;
    8)
        centos8Install
    ;;
    esac
}

check() {
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo docker run hello-world
}

case $RELEASE in
    ubuntu)
        ubuntuInstall
    ;;
    centos)
        centosInstall
    ;;
esac
check

}