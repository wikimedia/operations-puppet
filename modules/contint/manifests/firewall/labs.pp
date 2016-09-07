# vim: set ts=4 sw=4 et:

# == Class contint::firewall::labs
#
# Firewall rules for contint Jenkins slaves. Basically let the Jenkins masters
# to ssh to the slaves box.
class contint::firewall::labs {
    ferm::service { 'gallium_ssh_to_slaves':
        proto  => 'tcp',
        port   => '22',
        srange => '@resolve(gallium.wikimedia.org)'
    }

    ferm::service { 'contint1001_ssh_to_slaves':
        proto  => 'tcp',
        port   => '22',
        srange => '@resolve(contint1001.wikimedia.org)'
    }
}
