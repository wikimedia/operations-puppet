# SPDX-License-Identifier: Apache-2.0
# Class: profile::druid::conftool
#
# Add conftool configurations and util scripts
# to pool/depool services if the Druid cluster
# is behind a LVS load balancer.
#
class profile::druid::conftool {

    include ::profile::conftool::client
    class { 'conftool::scripts': }

}