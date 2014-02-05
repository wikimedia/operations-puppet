# Class: postgresql::server
#
# This class installs postgresql packages, standard configuration
#
# Parameters:
#   pgversion
#       Defaults to 9.1. Valid values 8.4, 9.1 in Ubuntu
#   ensure
#       Defaults to present
#
# Actions:
#  Install/configure postgresql
#
# Requires:
#
# Sample Usage:
#  include postgresql::server

class postgresql::server(
                        $pgversion='9.1',
                        $ensure='present'
                        ) {
    package { [
            "postgresql-${pgversion}",
            "postgresql-${pgversion}-debversion",
            "postgresql-client-${pgversion}",
            'libdbi-perl',
            'libdbd-pg-perl',
        ]:
        ensure    => $ensure,
    }

    $run = $ensure ? {
        'present'   => 'running',
        'absent'    => 'stopped',
        'purged'    => 'stopped',
        default     => 'running',
    }

    exec { 'pgreload':
        command     => "/usr/bin/pg_ctlcluster $pgversion main reload",
        user        => 'postgres',
        refreshonly => true,
    }

    service { 'postgresql':
        ensure  => $run,
        require => Package["postgresql-$pgversion"]
    }
}
