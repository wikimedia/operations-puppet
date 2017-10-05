# https://racktables.wikimedia.org

## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables
#
class role::racktables {

    system::role { 'racktables': description => 'Racktables server' }

    include ::standard
    include ::profile::racktables
}
