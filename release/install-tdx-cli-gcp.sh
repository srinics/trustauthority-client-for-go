#!/bin/bash
#
# Copyright (c) 2024 Intel Corporation
# All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# 
# Script used to  install Intel Trust Authority Client for GCP ( GCP Confidential VM). This script will run in Ubuntu/RHEL/SUSE 
# Linux Distribution (not supported in other OS flavours). Run the below command in Linux terminal to install this CLI.
# curl https://raw.githubusercontent.com/intel/trustauthority-client-for-go/main/release/install-tdx-cli-gcp.sh | sudo bash -

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
#TODO need to change REPO_URL
readonly REPO_URL="srinics/trustauthority-client-for-go"
readonly CLI_NAME="Intel Trust Authority Client for GCP"
readonly RAW_MAKEFILE="https://raw.githubusercontent.com/${REPO_URL}/main/tdx-cli/Makefile"
if [ -z "${CLI_VERSION}" ]; then
    CLI_VERSION=$(curl  --silent  https://api.github.com/repos/${REPO_URL}/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
fi
readonly INSTALL_DIRECTORY=/usr/bin
readonly TAR_NAME="trustauthority-cli-gcp-${CLI_VERSION}.tar.gz"
readonly README_LINK="https://github.com/${REPO_URL}/tree/gcp-tdx-preview/tdx-cli#usage"
readonly CLI_BIN=$(curl -s ${RAW_MAKEFILE}  | grep "^APPNAME.*=" | sed -e "s/APPNAME.*=\(\s\+\)\?//g")
readonly URL="https://github.com/${REPO_URL}/releases/download/${CLI_VERSION}/${TAR_NAME}"

installation_intrupted()
{
    printf "\n%b%s installation interrupted by signal !!%b\n\n" "${CODE_ERROR}" "${CLI_NAME}" "${CODE_NC}"
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

pushd /tmp > /dev/null
#If already cli tar available, removing it
if [ -f ${TAR_NAME} ]; then
    rm -r ${TAR_NAME} 
fi
curl -fsLO "${URL}" > /dev/null  || print_error_and_exit
tar xvf "${TAR_NAME}" -C "${INSTALL_DIRECTORY}" > /dev/null || print_error_and_exit
rm -rf "${TAR_NAME}"
popd > /dev/null

printf "\n%s installed in %s%s\n\n" "${CLI_NAME}" "${INSTALL_DIRECTORY}/${CLI_BIN}"
printf "\n%b%s installation successful !!%b\n\n" "${CODE_OK}" "${CLI_NAME}" "${CODE_NC}"
printf "\nFor usage %s please refer %s\n\n" "${CLI_NAME}" "${README_LINK}"
exit 0
