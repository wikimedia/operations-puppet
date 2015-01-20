# vim: set ts=4 sw=4 et:

# == Class contint::firewall::labs
#
# Firewall rules for contint Jenkins slaves. Basically let the Jenkins master
# to ssh to the slave box.
class contint::firewall::labs {
    ferm::rule { 'gallium_ssh_to_slaves':
        rule => 'proto tcp dport ssh { saddr 208.80.154.135 ACCEPT; }'
    }
}
