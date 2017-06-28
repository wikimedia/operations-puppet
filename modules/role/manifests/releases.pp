# == Class: role::releases
#
# Sets up a machine to generate and host releases of software
class role::releases {

    system::role { 'releases':
        ensure      => 'present',
        description => 'Wikimedia Software Releases Server',
    }

    include ::standard
    include ::base::firewall
    include ::profile::backup::host
    include ::profile::releases::mediawiki
    include ::profile::releases::reprepro
}
