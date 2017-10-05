# https://racktables.wikimedia.org
## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables
#
# filtertags: labs-project-servermon
class profile::racktables (
    $racktables_host = hiera('profile::racktables::racktables_host'),
){

    include ::apache
    include ::apache::mod::php5
    include ::apache::mod::ssl
    include ::apache::mod::rewrite
    include ::apache::mod::headers

    include ::passwords::racktables

    ferm::service { 'racktables-http':
        proto => 'tcp',
        port  => '80',
    }

    class { '::racktables':
        racktables_host    => $racktables_host,
        racktables_db_host => 'm1-master.eqiad.wmnet',
        racktables_db      => 'racktables',
    }
}
