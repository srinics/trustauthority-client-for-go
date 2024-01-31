#!/bin/bash
#
# Copyright (c) 2024 Intel Corporation
# All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# 
# Script used to  install Intel Trust Authority Client for Azure ( Azure Confidential VM). This script will run in Ubuntu/RHEL/SUSE 
# Linux Distribution (not supported in other OS flavours). Run the below command in Linux terminal to install this CLI.
# curl https://raw.githubusercontent.com/intel/trustauthority-client-for-go/main/release/install-tdx-cli-azure.sh | sudo bash -

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
readonly REPO_URL="srinics/trustauthority-client-for-go"
readonly CLI_NAME="Intel Trust Authority Cliect for Azure"
readonly RAW_MAKEFILE="https://raw.githubusercontent.com/${REPO_URL}/main/tdx-cli/Makefile"
if [ -z "${CLI_VERSION}" ]; then
CLI_VERSION=$(curl  --silent  https://api.github.com/repos/${REPO_URL}/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
fi
readonly INSTALL_DIRECTORY=/usr/bin
readonly TAR_NAME="trustauthority-cli-azure-${CLI_VERSION}.tar.gz"
readonly OS_DISTRO=$(cat /etc/os-release  | grep "^ID=" | sed -e "s/ID=//g")
readonly OS_DISTRO_VERSION=$(cat /etc/os-release  | grep "^VERSION_ID=" | tr -d '"' | sed -e "s/^VERSION_ID=\(\s\+\)\?\(.*\)\(\s\+\)\?$/\2/g")
readonly README_LINK="https://github.com/${REPO_URL}/tree/azure-tdx-preview/tdx-cli"
readonly CLI_BIN=$(curl -s ${RAW_MAKEFILE}  | grep "^APPNAME.*=" | sed -e "s/APPNAME.*=\(\s\+\)\?//g")
readonly URL="https://github.com/${REPO_URL}/releases/download/${CLI_VERSION}/${TAR_NAME}"

installation_intrupted()
{
    printf "\n%b%s Installation intruputed by signal !!%b\n\n" "${CODE_ERROR}" "${CLI_NAME}" "${CODE_NC}"
}

if [ "${OS}" != "Linux" ]; then
    printf "\n%bUnsupported OS Distribution - %s %b\n\n" "${CODE_ERROR}" "${OS}" "${CODE_NC}"
    print_error_and_exit
fi

printf "\n%s installation started.........\n\n" "${CLI_NAME}"

printf "\nDownloading %s ... from %s\n\n" "${CLI_NAME}" "${URL}"
if ! curl -sIf "${URL}" > /dev/null; then
    printf "\n%b%s - %s is not found%b\n\n" "${CODE_ERROR}" "${CLI_NAME}" "${URL}" "${CODE_NC}"
    print_error_and_exit
fi


if [ "${OS_DISTRO}" == "ubuntu" ] && [ "${OS_DISTRO_VERSION}" == "20.04" ]; then
    apt-get -qq install tpm2-tools=4.1.1-1ubuntu0.20.04.1 -y || print_error_and_exit
elif [ "${OS_DISTRO}" == "ubuntu" ] && [ "${OS_DISTRO_VERSION}" == "22.04" ]; then
    apt-get -qq install tpm2-tools=5.2-1build1 -y || print_error_and_exit
elif [ "${OS_DISTRO}" == "rhel" ]; then
    dnf install tpm2-tools libtss2-tcti-device0 -y || print_error_and_exit
elif ( [[ "${OS_DISTRO}" == "opensuse"* ]] || [ "${OS_DISTRO}" == "sles" ] ) && [ "${OS_DISTRO_VERSION}" == "15.5" ]; then
    zypper install tpm2-tools=5.2-150400.4.6 libtss2-tcti-device0=3.1.0-150400.3.3.1 -y || print_error_and_exit
else 
    printf "\n%bUnsupported Linux Distribution - %s-%s %b\n\n" "${CODE_ERROR}" "${OS_DISTRO}" "${OS_DISTRO_VERSION}" "${CODE_NC}"
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
