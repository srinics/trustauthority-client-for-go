#!/bin/bash
#Script to install Intel Trust Authority TDX Cli binary one click installation
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
curl --version > /dev/null || print_error_and_exit 'curl package not found - please install and proceed'


readonly OS=$(uname)
readonly CLI_NAME="Intel Trust Authority - Azure TDX CLI"
readonly RAW_MAKEFILE="https://raw.githubusercontent.com/intel/trustauthority-client-for-go/main/tdx-cli/Makefile"
readonly VERSION=$(curl -s ${RAW_MAKEFILE}  | grep "^VERSION.*=" | sed -e "s/VERSION.*=\(\s\+\)\?//g")
readonly INSTALL_DIRECTORY=/usr/local/bin
readonly TAR_NAME="trustauthority-cli-azure-${VERSION}.tar.gz"
readonly OS_DISTRO=$(cat /etc/os-release  | grep "^ID=" | sed -e "s/ID=//g")
readonly README_LINK="https://github.com/intel/trustauthority-client-for-go/tree/azure-tdx-preview/tdx-cli"
readonly CLI_BIN=$(curl -s ${RAW_MAKEFILE}  | grep "^APPNAME.*=" | sed -e "s/APPNAME.*=\(\s\+\)\?//g")
#TODO need to change opensource path - this is temporary
readonly URL="https://github.com/srinics/trustauthority-client-for-go/releases/download/${VERSION}/${TAR_NAME}"

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

if [ "${OS_DISTRO}" == "ubuntu" ]; then
    apt-get -qq install tpm2-tools -y || print_error_and_exit
elif [ "${OS_DISTRO}" == "rhel" ]; then
    dnf install tpm2-tools -y || print_error_and_exit
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
printf "\nFor runing %s please refer %s\n\n" "${CLI_NAME}" "${README_LINK}"
exit 0
