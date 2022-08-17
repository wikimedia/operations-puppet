# SPDX-License-Identifier: Apache-2.0
# Class: role::dispatch::backend
#
# This role runs the Dispatch backend (e.g. DB)
#
# Actions:
#       Deploy Dispatch database server
#
# Requires:
#
# Sample Usage:
#       role(dispatch::backend)
#

class role::dispatch::backend {
    include profile::base::production

    system::role { 'dispatch::backend': description => 'Dispatch backend (e.g. DB)' }

    include profile::dispatch::db
    include profile::prometheus::postgres_exporter
    include profile::base::firewall
}
