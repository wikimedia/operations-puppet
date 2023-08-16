# SPDX-License-Identifier: Apache-2.0
# @summary Installs confd and monitoring/logging setup
# @param ensure the ensure parameter
class confd(
    Wmflib::Ensure $ensure = present,
) {

    ### Install confd ###
    package { 'confd':
        ensure => $ensure,
    }
    ensure_packages(['python3-toml'])

    ### Alerting - error checks ###
    # Install the check file wrapper that allows us to be notified if a template check fails.
    # Please note - this will be common to all instances.
    file { '/usr/local/bin/confd-lint-wrap':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/confd/confd-lint-wrap.py',
    }

    nrpe::plugin { 'check_confd_lint':
        source => 'puppet:///modules/confd/check_confd_lint.sh';
    }

    # Cleanup stale confd errors
    # https://phabricator.wikimedia.org/T321678
    $run_dir = '/var/run/confd-template'

    # Force creation here to avoid find complaining with
    # find: ‘/var/run/confd-template’: No such file or directory
    # Normally confd creates the directory on errors
    file { $run_dir:
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    systemd::timer::job { 'clean-confd-rundir':
        ensure      => $ensure,
        description => "Clean old stale files in ${run_dir}",
        user        => 'root',
        interval    => {'start' => 'OnCalendar', 'interval' => '*:0/30'},  # Every 30 minutes
        command     => "/usr/bin/find ${run_dir} -mtime +30 -delete",
        require     => File[$run_dir],
    }

    # Used by modules/profile/files/mediawiki/maintenance/mw-cli-wrapper.py
    nrpe::plugin { 'check_confd_template':
        source => 'puppet:///modules/confd/check_confd_template';
    }

    # prometheus check script
    file { '/usr/local/bin/confd-prometheus-metrics':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/confd/confd_prometheus_metrics.py',
    }

    # Log to a dedicated file
    logrotate::conf { 'confd':
        ensure => present,
        source => 'puppet:///modules/confd/logrotate.conf',
    }

    rsyslog::conf { 'confd':
        source   => 'puppet:///modules/confd/rsyslog.conf',
        priority => 20,
        require  => File['/etc/logrotate.d/confd'],
    }

}
