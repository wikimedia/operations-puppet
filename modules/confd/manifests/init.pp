# SPDX-License-Identifier: Apache-2.0
# == Class confd
#
# Installs confd and monitoring/logging setup
#
class confd(
    Wmflib::Ensure   $ensure        = present,
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

    # Force creation here to avoid the following spam from puppet:
    # Info: /Stage[main]/Confd/Tidy[/var/run/confd-template]: File does not exist
    # Normally confd creates the directory on errors
    file { $run_dir:
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    tidy { $run_dir:
        age     => '30m',
        type    => 'mtime',
        recurse => true,
        backup  => false,
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
