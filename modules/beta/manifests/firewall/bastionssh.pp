# == Class beta::firewall::bastionssh
#
# Firewall rules for contint Jenkins slaves. Allow ssh from beta bastion.
class beta::firewall::bastionssh {

    include base::firewall

     ferm::rule { 'ssh-from-beta-bastion':
        rule => 'proto tcp dport ssh { saddr 10.4.0.58 ACCEPT; }',
    }

}
