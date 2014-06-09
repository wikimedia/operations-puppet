# == Class exim4::ganglia
# This installs a Ganglia plugin for exim4, using gmetric
#
class exim4::ganglia {
    file { '/usr/local/bin/collect_exim_stats_via_gmetric':
        owner  => 'root',
        group  => 'Debian-exim',
        mode   => '0755',
        source => 'puppet:///modules/exim4/ganglia/collect_exim_stats_via_gmetric',
    }

    cron { 'collect_exim_stats_via_gmetric':
        ensure  => present,
        user    => 'root',
        command => '/usr/local/bin/collect_exim_stats_via_gmetric',
        require => File['/usr/local/bin/collect_exim_stats_via_gmetric'],
    }
}
