# == Class: role::releases
#
# Sets up a machine to generate and host releases of software
class role::releases {

    system::role { 'releases':
        ensure      => 'present',
        description => 'Wikimedia Software Releases Server',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::backup::host
    include ::profile::releases::common
    include ::profile::releases::mediawiki
    include ::profile::releases::mediawiki::security
    include ::profile::releases::reprepro
    include ::profile::releases::parsoid
    include ::profile::releases::blubber
}
