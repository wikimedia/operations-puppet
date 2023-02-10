#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

# This script is the collection of the upstream-recommended steps to
# set up a kolla-ansible evaluation deployment in a single node
# This script is not intended for production usage, just research & evaluation

# see https://docs.openstack.org/kolla-ansible/zed/user/quickstart.html
# see https://phabricator.wikimedia.org/T267433

set -ex

if [ "$(id -u)" == "0" ] ; then
    echo "ERROR: intended to be run as normal user, not root."
    exit 1
fi

sudo apt install python3-venv -y

python3 -m venv venv
# shellcheck source=/dev/null
source venv/bin/activate

pip install -U pip
pip install "ansible>=4,<6"
pip install git+https://opendev.org/openstack/kolla-ansible@stable/zed

sudo mkdir -p /etc/kolla
sudo chown "$USER":wikidev /etc/kolla

cp -r venv/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
cp venv/share/kolla-ansible/ansible/inventory/all-in-one .

sudo mkdir -p /etc/ansible
sudo chown "$USER":wikidev /etc/ansible
cat << EOF > /etc/ansible/ansible.cfg
[defaults]
host_key_checking=False
pipelining=True
forks=100
EOF

ansible -i all-in-one all -m ping

kolla-genpwd

cat << EOF > /etc/kolla/globals.yml
---
workaround_ansible_issue_8743: yes
kolla_base_distro: "debian"
kolla_internal_vip_address: "$(facter networking.ip)"
network_interface: "$(facter networking.primary)"
neutron_external_interface: "dummy1"
enable_haproxy: "no"
nova_compute_virt_type: "qemu"
EOF

##########
## WARNING: workaround for https://bugs.launchpad.net/kolla-ansible/+bug/1989791
old_line="$(facter networking.ip) $(facter hostname).$(facter domain) $(facter hostname)"
new_line="$(facter networking.ip) $(facter hostname) $(facter hostname).$(facter domain)"
sudo sed -i s/"$old_line"/"$new_line"/g /etc/hosts
## END OF WARNING
##########

# we don't care if this fails, not really important
sudo ip link add dummy1 type dummy || true

kolla-ansible install-deps
# may or may not be required, not documented by upstream, and some times not
# installed by the previoyus install-deps above. Not very deterministic...
pip install docker

kolla-ansible -i all-in-one bootstrap-servers
kolla-ansible -i all-in-one prechecks
kolla-ansible -i all-in-one deploy

# at this point everything is installed

pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/zed
kolla-ansible post-deploy

# this creates/defines some basic demo content on the cloud
venv/share/kolla-ansible/init-runonce

# finally, use the CLI
sudo cp /etc/kolla/clouds.yaml /etc/openstack/
sudo chmod a+r /etc/openstack/clouds.yaml
openstack --os-cloud=kolla-admin endpoint list
