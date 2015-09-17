#! /bin/sh

set -x

if ! which wget > /dev/null 2>&1; then
  yum install -y wget
fi

if ! which unzip > /dev/null 2>&1; then
  yum install -y unzip
fi

packer_install() {
  local version=$1
  local install_dir=/opt/packer

  if [ ! -d ${install_dir} ]; then
    mkdir -p ${install_dir}
  fi

  if [ ! -f ${install_dir}/packer ]; then
    file_name="packer_${version}_linux_386.zip"
    if [ "${hw_platform}" == "x86_64" ]; then
      file_name="packer_${version}_linux_amd64.zip"
    fi

    cd ${install_dir}
    wget -N https://dl.bintray.com/mitchellh/packer/${file_name} || return $?
    unzip ${file_name} -d /opt/packer
  fi
}

VERSION=0.7.5

while getopts v: OPT
do
  case $OPT in
    "v" ) VERSION="$OPTARG";;
  esac
done

packer_install $VERSION
