#!/bin/sh -ex

if ! bash -c "yum list installed | grep openssl"; then
  yum install -y openssl
fi

script_root=$(cd $(dirname $0)/data && pwd)
cd ${script_root}

cat ${script_root}/lib/install_ruby.sh | bash -s -- -v 2.1.5 -d /opt/ruby

#export PATH=$PATH:/opt/ruby/bin

#gem install bundler
