#!/bin/sh -x

cd $(dirname $0)/data

script_root=$(cd $(dirname $0)/data && pwd)

version=0.8.6
cat ${script_root}/lib/install_packer.sh | bash -s -- -v ${version}

/opt/packer/packer --version

version=0.9.0
cat ${script_root}/lib/install_packer.sh | bash -s -- -v ${version}

/opt/packer/packer --version

cat ${script_root}/lib/install_packer.sh | bash -s -- -v ${version}
