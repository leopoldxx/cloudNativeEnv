#! /bin/bash

[[ ${DEBUG} == "on" ]] && { set -x; }
set -e

{
    curl https://raw.githubusercontent.com/leopoldxx/cloudNativeEnv/master/install-docker.sh | bash
    curl https://raw.githubusercontent.com/leopoldxx/cloudNativeEnv/master/install-k8s.sh | bash
    curl https://raw.githubusercontent.com/leopoldxx/cloudNativeEnv/master/install-dev.sh  | bash
    curl https://raw.githubusercontent.com/leopoldxx/cloudNativeEnv/master/install-helm.sh | bash
}