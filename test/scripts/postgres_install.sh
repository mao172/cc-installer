#!/bin/sh -ex

script_root=$(cd $(dirname $0)/data && pwd)
cd ${script_root}

version=9.4

cat ${script_root}/lib/install_postgresql.sh | bash -s -- -v ${version}
