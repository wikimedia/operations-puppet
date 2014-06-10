# == Class exim4::ganglia
# This installs a Ganglia plugin for exim4, using gmetric
#
class exim4::ganglia {
    file { '/usr/local/bin/exim-to-gmetric':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/exim4/ganglia/exim-to-gmetric',
    }

    cron { 'collect_exim_stats_via_gmetric':
        ensure  => present,
        user    => 'root',
        command => '/usr/local/bin/exim-to-gmetric',
        require => File['/usr/local/bin/exim-to-gmetric'],
    }
}
