#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
if [ "$(uname -p)" == "arm" ]
then
  base_image="debian:bullseye"
else
  base_image="docker-registry.wikimedia.org/bullseye"
fi
# TODO: migrate the docker image to:
#  https://gitlab.wikimedia.org/repos/releng/dev-images
docker_file=$(cat <<EOF
FROM ${base_image}
ENV container docker
RUN apt-get update -y
RUN apt-get install -y git ruby-rubygems
RUN gem install puppet-debugger
RUN mkdir -p /etc/puppetlabs/code/environments
COPY hiera.yaml /etc/puppetlabs/puppet/hiera.yaml
ENTRYPOINT ["puppet", "debugger"]
EOF
)
if ! docker images | grep -qE  "^puppet-debugger\b"
then
  hiera_source="${script_dir}/../modules/puppetmaster/files/hiera/production.yaml"
  printf "build puppet-debugger image\n"
  work_dir=$(mktemp -d)
  pushd "${work_dir}" || exit
  # docker needs COPYed files to be relative
  sed 's|/etc/puppet|/etc/puppetlabs|g' "${hiera_source}" > hiera.yaml
  printf "%s" "${docker_file}" > Dockerfile
  docker build -t puppet-debugger .
  popd || exit
  rm -rf "${work_dir}"
fi
# We just use the two predefined empty modules paths instead of trying to update modulepath
docker run --rm -it \
  --mount type=bind,source="${script_dir}"/../modules,target=/etc/puppetlabs/code/modules \
  --mount type=bind,source="${script_dir}"/../vendor_modules,target=/opt/puppetlabs/puppet/modules  \
  --mount type=bind,source="${script_dir}"/../hieradata,target=/etc/puppetlabs/hieradata  \
  puppet-debugger

