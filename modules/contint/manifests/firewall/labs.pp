# vim: set ts=4 sw=4 et:

# == Class contint::firewall::labs
#
# Firewall rules for contint Jenkins slaves. Basically let the Jenkins master
# to ssh to the slave box.
class contint::firewall::labs {
    ferm::service { 'gallium_ssh_to_slaves':
        proto  => 'tcp',
        port   => '22',
        srange => '(( @resolve(gallium.wikimedia.org) ))'
    }
}
