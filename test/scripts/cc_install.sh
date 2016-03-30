#! /bin/sh -ex

script_root=$(cd $(dirname $0)/data && pwd)
cd ${script_root}

# packer_install
cat ${script_root}/lib/install_packer.sh | bash -s -- -v 0.9.0

# db_setup
cat ${script_root}/lib/setup_db.sh | bash -s -- -v 9.4 -u dbuser -p dbpswd

# cc_install
cat ${script_root}/lib/install_conductor.sh | bash -s -- -v 1.1.0
