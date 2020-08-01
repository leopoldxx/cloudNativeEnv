#! /bin/bash
{
[[ ${DEBUG} == "on" ]] && { set -x; }
set -e

RELEASE=$(cat /etc/os-release | grep -i '^ID='  | awk -F'=' '{print $2}' | tr -d '"')
VERSION=$(cat /etc/os-release | grep -i '^VERSION_ID='  | awk -F'=' '{print $2}' | tr -d '"')

GOVER='1.13.14'

sourceEnv() {
    export WORKROOT='/data/devenv'
    mkdir -p ${WORKROOT}
    cat  <<EOF | tee ${WORKROOT}/.devenv
export WORKROOT='/data/devenv'
export GOROOT=\${WORKROOT}/workspace/go/download/go
export GOPATH=\${WORKROOT}/workspace/go/

mkdir -p \${GOPATH}/{src,bin,pkg} ${GOROOT}

export PATH=\${GOROOT}/bin:\${GOPATH}/bin:\$PATH
export LC_ALL=en_US.UTF8

alias ll='ls -al'
alias kapply='kubectl apply -f '
alias kdelete='kubectl delete -f '
EOF
    sudo chmod 0666 ${WORKROOT}/.devenv

    if ! grep -iq '.devenv' ${HOME}/.bashrc;
    then
        echo "source ${WORKROOT}/.devenv" >>${HOME}/.bashrc
    fi
    source ${HOME}/.bashrc
}

installGo() {
    mkdir -p ${WORKROOT}/workspace/go/download/
    rm -f ${WORKROOT}/workspace/go/download/go${GOVER}.linux-amd64.tar.gz
    wget https://golang.google.cn/dl/go${GOVER}.linux-amd64.tar.gz -O ${WORKROOT}/workspace/go/download/go${GOVER}.linux-amd64.tar.gz
    tar xzvf ${WORKROOT}/workspace/go/download/go${GOVER}.linux-amd64.tar.gz -C ${WORKROOT}/workspace/go/download/
}

installUbuntuMisc() {
    sudo apt install -y git
}
installCentoSMisc() {
    sudo yum install -y git perl-Digest-SHA
}

installMisc() {
    case $RELEASE in
        ubuntu)
            installUbuntuMisc
        ;;
        centos)
            installCentoSMisc
        ;;
    esac
}

sourceEnv

installGo
installMisc
exec bash

}