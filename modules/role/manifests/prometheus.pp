# SPDX-License-Identifier: Apache-2.0
class role::prometheus {
    include profile::base::production
    include profile::firewall

    include profile::lvs::realserver

    include profile::prometheus::common

    # XXX clean up moved instances
    prometheus::instances().each |$instance, $config| {
        if $facts['networking']['fqdn'] in $config['hosts'] {
            include "profile::prometheus::${instance}"
        }
    }

    # Instances not yet migrated to prometheus::instances
    $unassigned_instance_hosts = lookup('prometheus::unassigned_instance_hosts') # lint:ignore:wmf_styleguide
    if $facts['networking']['fqdn'] in $unassigned_instance_hosts {
        include profile::prometheus::k8s
    }

    include profile::prometheus::pushgateway

    include profile::alerts::deploy::prometheus

    include profile::prometheus::rsyncd
    include profile::prometheus::web

    include profile::prometheus::web_idp
}
