# == Class beta::firewall::bastionssh
#
# Firewall rules for contint Jenkins slaves. Allow ssh from beta bastion.
class beta::firewall::bastionssh {

    include base::firewall

    ferm::service { 'ssh-from-beta-bastion':
        proto => 'tcp',
        port => 'ssh',
        srange => ' 10.4.0.58',
    }

}
