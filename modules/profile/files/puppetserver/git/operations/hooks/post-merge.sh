#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
/usr/bin/sudo /usr/bin/g10k -config /etc/puppet/g10k.conf
# Evict the code cache from puppetserver, so it can pick up the g10k deploy
sudo /usr/local/bin/puppetserver-evict-code-cache
