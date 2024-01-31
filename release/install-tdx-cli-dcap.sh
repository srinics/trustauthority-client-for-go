#!/bin/bash
# Copyright (c) 2024 Intel Corporation
# All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# 
# Script used to  install Intel Trust Authority Client This script will run in Ubuntu/RHEL/SUSE  Linux Distribution 
# (not supported in other OS flavours). Run the below command in Linux terminal to install this CLI.
# curl https://raw.githubusercontent.com/intel/trustauthority-client-for-go/main/release/install-tdx-cli-dcap.sh | sudo bash -

set -e

readonly CODE_ERROR='\033[0;31m' #RED_COLOR
readonly CODE_OK='\033[0;32m'  #GREEN_COLOR
readonly CODE_WARNING='\033[0;33m' #BROWN/ORANGE_COLOR   
readonly CODE_NC='\033[0m' #NO_COLOR`

print_error_and_exit()
{
    printf "\n\n%b%s Installation failed !!%b\n\n\n" "${CODE_ERROR}" "${CLI_NAME:=Trust Authority CLI}" "${CODE_NC}"
    if [[ ! -z $1 ]]; then
	    printf "%bError: %s%b\n\n\n" "${CODE_ERROR}" "${1}" "${CODE_NC}"
    fi
    exit 1
}

trap 'installation_intrupted' 1 2 3 6

readonly OS=$(uname)
#TODO need to change repo url
readonly REPO_URL="srinics/trustauthority-client-for-go"
readonly RAW_MAKEFILE="https://raw.githubusercontent.com/${REPO_URL}/main/tdx-cli/Makefile"
if [ -z "${CLI_VERSION}" ]; then
CLI_VERSION=$(curl  --silent  https://api.github.com/repos/${REPO_URL}/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
fi
readonly INSTALL_DIRECTORY=/usr/bin
readonly OS_DISTRO=$(cat /etc/os-release  | grep "^ID=" | sed -e "s/^ID=\(\s\+\)\?\(.*\)\(\s\+\)\?$/\2/g")
readonly OS_DISTRO_VERSION=$(cat /etc/os-release  | grep "^VERSION_ID=" | tr -d '"' | sed -e "s/^VERSION_ID=\(\s\+\)\?\(.*\)\(\s\+\)\?$/\2/g")
readonly TAR_NAME="trustauthority-cli-${OS_DISTRO}-${CLI_VERSION}.tar.gz"
readonly README_LINK="https://github.com/${REPO_URL}/tree/master/tdx-cli"
readonly CLI_BIN=$(curl -s ${RAW_MAKEFILE}  | grep "^APPNAME.*=" | sed -e "s/APPNAME.*=\(\s\+\)\?//g")
readonly URL="https://github.com/${REPO_URL}/releases/download/${CLI_VERSION}/${TAR_NAME}"
readonly CLI_NAME="Intel Trust Authority Client for ${OS_DISTRO^^}"



installation_intrupted()
{
    printf "\n%b%s Installation intruputed by signal !!%b\n\n" "${CODE_ERROR}" "${CLI_NAME}" "${CODE_NC}"
}


if [ "${OS}" != "Linux" ]; then
    printf "\n%bUnsupported OS Distribution - %s %b\n\n" "${CODE_ERROR}" "${OS}" "${CODE_NC}"
    print_error_and_exit
fi

if [ "${OS_DISTRO}" == "ubuntu" ] && [ "${OS_DISTRO_VERSION}" == "20.04" ]; then
    echo 'deb [arch=amd64] https://download.01.org/intel-sgx/sgx_repo/ubuntu focal main' | tee /etc/apt/sources.list.d/intel-sgx.list || print_error_and_exit
    pushd /tmp > /dev/null
    wget -qO - https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key | apt-key add  || print_error_and_exit
    rm -f intel-sgx-deb.key
    popd
elif [ "${OS_DISTRO}" == "ubuntu" ] && [ "${OS_DISTRO_VERSION}" == "22.04" ]; then
    echo 'deb [signed-by=/etc/apt/keyrings/intel-sgx-keyring.asc arch=amd64] https://download.01.org/intel-sgx/sgx_repo/ubuntu jammy main' | tee /etc/apt/sources.list.d/intel-sgx.list || print_error_and_exit
    pushd /tmp > /dev/null
    wget -qO - https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key || print_error_and_exit
    cat intel-sgx-deb.key | tee /etc/apt/keyrings/intel-sgx-keyring.asc > /dev/null || print_error_and_exit
    rm -f intel-sgx-deb.key
    popd
elif [ "${OS_DISTRO}" == "rhel" ] && [ "${OS_DISTRO_VERSION}" = "9.2" ]; then
    pushd /tmp > /dev/null
    wget -q0 - https://download.01.org/intel-sgx/latest/linux-latest/distro/${OS_DISTRO}${OS_DISTRO_VERSION}-server/sgx_rpm_local_repo.tgz || print_error_and_exit
    wget -q0 - https://download.01.org/intel-sgx/latest/dcap-latest/linux/SHA256SUM_dcap_1.19.cfg || print_error_and_exit
    sha256sum sgx_rpm_local_repo.tgz || print_error_and_exit
    tar xvf sgx_rpm_local_repo.tgz || print_error_and_exit
    yum-config-manager --add-repo file:/tmp/sgx_rpm_local_repo || print_error_and_exit
    dnf --nogpgcheck install libtdx-attest-devel -y > /dev/null || print_error_and_exit
    popd
elif ([[ "${OS_DISTRO}" == "opensuse"* ]] || ["${OS_DISTRO}" == "sles" ]] ) && [[ "${OS_DISTRO_VERSION}" = "15"* ]]; then
    pushd /tmp > /dev/null
    wget -q0 - https://download.01.org/intel-sgx/latest/linux-latest/distro/suse${OS_DISTRO_VERSION}-server/sgx_rpm_local_repo.tgz || print_error_and_exit
    wget -q0 - https://download.01.org/intel-sgx/latest/dcap-latest/linux/SHA256SUM_dcap_1.19.cfg || print_error_and_exit
    sha256sum sgx_rpm_local_repo.tgz || print_error_and_exit
    tar xvf sgx_rpm_local_repo.tgz || print_error_and_exit
    zypper addrepo /opt/intel/sgx_rpm_local_repo /tmp/sgx_rpm_local_repo || print_error_and_exit
    zypper --no-gpg-checks install libtdx-attest-devel -y  > /dev/null || print_error_and_exit
    popd
else 
    printf "\n%bUnsupported Linux Distribution - %s-%s %b\n\n" "${CODE_ERROR}" "${OS_DISTRO}" "${OS_DISTRO_VERSION}" "${CODE_NC}"
    print_error_and_exit
fi

if [ "${OS_DISTRO}" == "ubuntu" ]; then
    apt-get update -y > /dev/null || print_error_and_exit
    apt-get -qq install libtdx-attest-dev -y > /dev/null || print_error_and_exit
fi

printf "\n%s installation started.........\n\n" "${CLI_NAME}"

printf "\nDownloading %s ... from %s\n\n" "${CLI_NAME}" "${URL}"
if ! curl -sIf "${URL}" > /dev/null; then
    printf "\n%b%s - %s is not found%b\n\n" "${CODE_ERROR}" "${CLI_NAME}" "${URL}" "${CODE_NC}"
    print_error_and_exit
fi

pushd /tmp > /dev/null
#To ensure proviously downloaded removed
if [ -f ${TAR_NAME} ]; then
    rm -r ${TAR_NAME} 
fi
curl -fsLO "${URL}" > /dev/null  || print_error_and_exit
tar xvf "${TAR_NAME}" -C "${INSTALL_DIRECTORY}" > /dev/null || print_error_and_exit
rm -rf "${TAR_NAME}"
popd > /dev/null

printf "\n%s binary installated in %s%s\n\n" "${CLI_NAME}" "${INSTALL_DIRECTORY}/${CLI_BIN}"
printf "\n%b%s Installation successful !!%b\n\n" "${CODE_OK}" "${CLI_NAME}" "${CODE_NC}"
printf "\nFor usage %s please refer %s\n\n" "${CLI_NAME}" "${README_LINK}"
exit 0
