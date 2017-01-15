# Class: postgresql::packages
#
# This class installs postgresql packages. It is split off from the rest of the
# classes in order to allow them to require it with no side-effects
#
# Parameters:
#   pgversion
#       Defaults to 9.1 in Ubuntu Precise, 9.3 in Ubuntu Trusty,
#       and 9.4 in Debian Jessie. Ubuntu Precise may choose 8.4.
#       FIXME: Just use the unversioned package name and let apt
#       do the right thing.
#   ensure
#       Defaults to present
#
# Actions:
#  Install postgresql
#
# Requires:
#
# Sample Usage:
#  include postgresql::packages
#
class postgresql::packages(
    $pgversion        = $::lsbdistcodename ? {
        'jessie'  => '9.4',
        'precise' => '9.1',
        'trusty'  => '9.3',
    },
    $ensure           = 'present',
) {
    package { [
        "postgresql-${pgversion}",
        "postgresql-${pgversion}-debversion",
        "postgresql-client-${pgversion}",
        "postgresql-contrib-${pgversion}",
        'libdbi-perl',
        'libdbd-pg-perl',
        'ptop',
    ]:
        ensure => $ensure,
    }
}
