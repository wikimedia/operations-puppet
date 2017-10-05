## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables
#
# filtertags: labs-project-servermon
class profile::racktables {

    include ::standard
    include ::base::firewall
    include ::mysql
    include ::passwords::racktables
    include ::apache
    include ::apache::mod::php5
    include ::apache::mod::ssl
    include ::apache::mod::rewrite
    include ::apache::mod::headers

    ferm::service { 'racktables-http':
        proto => 'tcp',
        port  => '80',
    }

    class { '::racktables':
        racktables_host    => hiera('racktables_host', $facts['fqdn']),
        racktables_db_host => 'm1-master.eqiad.wmnet',
        racktables_db      => 'racktables',
    }
}
