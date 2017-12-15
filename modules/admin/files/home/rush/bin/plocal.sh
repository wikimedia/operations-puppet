#!/bin/bash
# shim to get started using utils/localrun
sudo puppet agent --test
cd /root
git clone https://gerrit.wikimedia.org/r/operations/puppet
cd /srv
git clone https://gerrit.wikimedia.org/r/labs/private
cd /root
ln -s /root/puppet/hieradata/ /etc/puppet/hieradata
ln -s /srv/private /etc/puppet/private
alias run='cd /root/puppet/utils/ && ./localrun'
