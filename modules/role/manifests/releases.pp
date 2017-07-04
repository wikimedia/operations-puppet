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

    rsync::quickdatacopy { 'srv-org-wikimedia-releases':
      ensure      => present,
      source_host => 'bromine.eqiad.wmnet',
      dest_host   => 'releases1001.eqiad.wmnet',
      module_path => '/srv/org/wikimedia/releases',
    }
}
