# SPDX-License-Identifier: Apache-2.0
# == Class profile::hadoop::balancer
#
# Runs hdfs balancer periodically to keep data balanced across all DataNodes
#
class profile::hadoop::balancer(
    Wmflib::Ensure $ensure  = lookup('profile::hadoop::balancer::ensure', { 'default_value' => 'present' }),
) {
    require ::profile::hadoop::common

    # This package provides the lockfile-check, lockfile-create, and lockfile-remove commands.
    ensure_packages('lockfile-progs')

    file { '/usr/local/bin/hdfs-balancer':
        source => 'puppet:///modules/profile/hadoop/hdfs-balancer',
        mode   => '0754',
        owner  => 'hdfs',
        group  => 'hdfs',
    }

    kerberos::systemd_timer { 'hdfs-balancer':
        ensure            => $ensure,
        description       => 'Run the HDFS balancer script to keep HDFS blocks replicated in the most redundant and efficient way.',
        command           => '/usr/local/bin/hdfs-balancer',
        interval          => '*-*-* 06:00:00',
        logfile_name      => 'balancer.log',
        logfile_basedir   => '/var/log/hadoop-hdfs',
        syslog_identifier => 'hdfs-balancer',
        require           => File['/usr/local/bin/hdfs-balancer'],
        user              => 'hdfs',
    }
}
