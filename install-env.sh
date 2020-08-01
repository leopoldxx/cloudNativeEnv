#! /bin/bash
{

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
sourceEnv
exec bash
}