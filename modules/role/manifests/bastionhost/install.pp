# a combination of bastion host and install server
# on a single machine
class role::bastionhost::install {

    system::role { 'bastionhost::install':
        description => 'Bastion host and install server',
    }

    include ::standard
    include ::base::firewall
    include ::bastionhost
    include ::profile::backup::host
    include ::profile::bastionhost::general
    include ::profile::scap::dsh  # Used by parsoid deployers

    include ::installserver::tftp
    include ::ipmi::mgmt
    include ::prometheus::ops

    backup::set {'home': }

    class { '::ganglia::monitor::aggregator': sites => $::site, }

}
