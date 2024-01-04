# Class: postgresql::dirs
#
# This class creates postgresql directories. It's split off from the rest of the
# classes in order to allow requiring it without causing dependency loops. You
# should not be using it directly
#
# Parameters:
#   pgversion
#       Defaults to 9.6 in Debian Stretch and 11 in Buster
#       FIXME: Just use the unversioned package name and let apt
#       do the right thing.
#   ensure
#       Defaults to present
#   root_dir
#       The root directory for postgresql data. The actual directory will be
#       "${root_dir}/${pgversion}/main".
#
# Actions:
#  Create postgres directories
#
# Requires:
#
# Sample Usage:
#  include postgresql::dirs
#
class postgresql::dirs(
    String            $ensure    = 'present',
    Stdlib::Unixpath  $root_dir  = '/var/lib/postgresql',
    Optional[Numeric] $pgversion = undef,
) {
    $_pgversion = $pgversion ? {
        undef   => $facts['os']['distro']['codename'] ? {
            'bullseye' => 13,
            'bookworm' => 15,
            default   => 11,
        },
        default => $pgversion,
    }
    $data_dir = "${root_dir}/${_pgversion}/main"
    $config_dir = "/etc/postgresql/${_pgversion}"

    # Also creates the 'postgres' user
    ensure_packages('postgresql-common')

    file {  [ $root_dir, "${root_dir}/${_pgversion}" ] :
        ensure  => stdlib::ensure($ensure, 'directory'),
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0755',
        require => Package['postgresql-common'],
    }

    file { $data_dir:
        ensure  => stdlib::ensure($ensure, 'directory'),
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0700',
        require => Package['postgresql-common'],
    }

    file {  [ $config_dir, "${config_dir}/main" ] :
        ensure  => stdlib::ensure($ensure, 'directory'),
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0755',
        require => Package['postgresql-common'],
    }
}
