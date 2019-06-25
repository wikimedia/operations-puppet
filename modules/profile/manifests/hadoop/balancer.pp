# == Class profile::hadoop::balancer
#
# Runs hdfs balancer periodically to keep data balanced across all DataNodes
#
class profile::hadoop::balancer(
    $use_kerberos       = hiera('profile::hadoop::balancer::use_kerberos', false),
) {
    require ::profile::hadoop::common

    if $use_kerberos {
        $wrapper = '/usr/local/bin/kerberos-puppet-wrapper hdfs '
    } else {
        $wrapper = ''
    }

    file { '/usr/local/bin/hdfs-balancer':
        source => 'puppet:///modules/profile/hadoop/hdfs-balancer',
        mode   => '0754',
        owner  => 'hdfs',
        group  => 'hdfs',
    }

    kerberos::systemd_timer { 'hdfs-balancer':
        description     => 'Run the HDFS balancer script to keep HDFS blocks replicated in the most redundant and efficient way.',
        command         => "${wrapper}/usr/local/bin/hdfs-balancer",
        interval        => '*-*-* 06:00:00',
        logfile_name    => 'balancer.log',
        logfile_basedir => '/var/log/hadoop-hdfs',
        require         => File['/usr/local/bin/hdfs-balancer'],
        user            => 'hdfs',
        use_kerberos    => $use_kerberos,
    }
}
