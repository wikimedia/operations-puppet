# https://racktables.wikimedia.org
## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables
#
class profile::racktables (
    Stdlib::Fqdn $racktables_host = lookup('profile::racktables::racktables_host'),
    Stdlib::Fqdn $racktables_db_host = lookup('profile::racktables::racktables_db_host'),
){
    system::role { 'racktables': description => 'Racktables server' }

    include ::profile::standard
    include ::passwords::racktables

    class { '::racktables':
        racktables_host    => $racktables_host,
        racktables_db_host => $racktables_db_host,
        racktables_db      => 'racktables',
    }
}
