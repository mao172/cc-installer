#!/bin/sh -ex

script_root=$(cd $(dirname $0)/data && pwd)
cd ${script_root}

cat ${script_root}/lib/setup_db.sh | bash -s -- -v 9.4 -u dbuser -p dbpswd
