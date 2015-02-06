# vim: set ts=4 sw=4 et:

# == Class contint::firewall::labs
#
# Firewall rules for contint Jenkins slaves.
class contint::firewall::labs {

	# Allow Jenkins master
    ferm::rule { 'gallium_ssh_to_slaves':
        rule => 'proto tcp dport ssh { saddr 208.80.154.135 ACCEPT; }'
    }

    # Allow other labs instances
    # This is already possible through bastion, but because contint overrides
    # iptables we have to re-allow it (eventhough our Nova security group already
    # allows this).
    # Use case: ssh from integration-dev to integratin-slave100x.
    ferm::rule { 'from_labs_to_labs':
        rule => 'proto tcp dport ssh { saddr 10.0.0.0/8 ACCEPT; }'
    }
}
