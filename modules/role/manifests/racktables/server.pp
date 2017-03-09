# https://racktables.wikimedia.org

## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables
#
# filtertags: labs-project-servermon
class role::racktables::server {

    system::role { 'role::racktables::server': description => 'Racktables server' }

    include ::standard
    include ::base::firewall

    $racktables_host = hiera('racktables_host'), $::fqdn)

    ferm::service { 'racktables-http':
        proto => 'tcp',
        port  => '80',
    }

    class { '::racktables':
        racktables_db_host => 'm1-master.eqiad.wmnet',
        racktables_db      => 'racktables',
    }
}
