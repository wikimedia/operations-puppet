# == Class: role::dmarc
#
# Sets up servers for DMARC processing
#
class role::dmarc {

    include ::profile::standard
    include ::profile::base::firewall

    system::role { 'dmarc':
        description => 'DMARC processing server',
    }
}
