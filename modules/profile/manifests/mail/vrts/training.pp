# SPDX-License-Identifier: Apache-2.0
# @summary
#     Configures VRTS mail filter training for SpamAssassin and Rspamd.
class profile::mail::vrts::training (
    Stdlib::Fqdn $active_host        = lookup('profile::vrts::active_host'),
    Stdlib::Fqdn $passive_host       = lookup('profile::vrts::passive_host'),
    Boolean      $train_spamassassin = lookup('profile::mail::vrts::training::train_spamassassin', { 'default_value' => true }),
    Boolean      $train_rspamd       = lookup('profile::mail::vrts::training::train_rspamd', { 'default_value' => true }),
) {
    $training_enabled = $train_spamassassin or $train_rspamd
    $training_ensure = ($facts['networking']['fqdn'] == $active_host and $training_enabled).bool2str('present', 'absent')


    if $train_rspamd {
        $rspamd_controller_endpoint = 'localhost:11334'

        class { 'rspamd':
            manage_package_repo => false,
        }

        profile::auto_restarts::service { 'rspamd': }

        file { '/etc/vrts/rspamd-controller.password':
            ensure => absent,
        }

        file { '/etc/rspamd/local.d/worker-controller.inc':
            ensure  => absent,
            require => Package['rspamd'],
            notify  => Service['rspamd'],
        }

        file { '/etc/rspamd/local.d/classifier-bayes.conf':
            ensure  => file,
            owner   => 'root',
            group   => '_rspamd',
            mode    => '0444',
            content => @(EOF),
                backend = "sqlite3";
                cache {
                  type = "sqlite3";
                  path = "/var/lib/rspamd/learn_cache.sqlite";
                }
                statfile {
                  symbol = "BAYES_HAM";
                  spam = false;
                  path = "/var/lib/rspamd/bayes.ham.sqlite";
                }
                statfile {
                  symbol = "BAYES_SPAM";
                  spam = true;
                  path = "/var/lib/rspamd/bayes.spam.sqlite";
                }
                | EOF
            require => Package['rspamd'],
            notify  => Service['rspamd'],
        }

        $rspamd_data_dir = '/var/lib/rspamd'
        $rspamd_backup_dir = '/var/lib/rspamd/backup'
        $rspamd_backup_script = '/usr/local/sbin/rspamd_sqlite_backup.py'
        $is_passive_host = $facts['networking']['fqdn'] == $passive_host
        $rspamd_sync_ensure = $is_passive_host.bool2str('present', 'absent')

        file { $rspamd_backup_dir:
            ensure  => directory,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            require => Package['rspamd'],
        }

        rsync::quickdatacopy { 'vrts-rspamd-data':
            source_host         => $active_host,
            dest_host           => $passive_host,
            module_path         => $rspamd_backup_dir,
            delete              => true,
            exclude             => '*.tmp',
            server_uses_stunnel => true,
            auto_sync           => false,
            require             => [
                Class['Rspamd'],
                File[$rspamd_backup_dir],
            ],
        }

        $rspamd_restore_command = join([
            $rspamd_backup_script,
            ' restore --backup-dir ',
            $rspamd_backup_dir,
            ' --target-dir ',
            $rspamd_data_dir,
        ], '')
        $rspamd_sync_command = join([
            '/bin/sh -c "',
            '/usr/local/sbin/sync-vrts-rspamd-data; ',
            'rc=$?; ',
            'if [ "$rc" -ne 0 ] && [ "$rc" -ne 24 ]; then exit "$rc"; fi; ',
            $rspamd_restore_command,
            ' && /bin/systemctl restart rspamd.service',
            '"',
        ], '')

        systemd::timer::job { 'vrts_sync_rspamd_data':
            ensure      => $rspamd_sync_ensure,
            user        => 'root',
            description => 'VRTS - sync Rspamd sqlite backups from the active host',
            command     => $rspamd_sync_command,
            interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:15:00'},
            require     => [
                Class['Rspamd'],
                File[$rspamd_backup_script],
                Rsync::Quickdatacopy['vrts-rspamd-data'],
            ],
        }

        $rspamd_args = [
            '--train-rspamd',
            '--rspamd-controller',
            $rspamd_controller_endpoint,
        ]
        $rspamd_backup_command = join([
            $rspamd_backup_script,
            ' backup --source-dir ',
            $rspamd_data_dir,
            ' --backup-dir ',
            $rspamd_backup_dir,
        ], '')
        $rspamd_requires = [
            Class['Rspamd'],
            File[$rspamd_backup_dir],
            File[$rspamd_backup_script],
        ]
    } else {
        $rspamd_args = []
        $rspamd_backup_command = ''
        $rspamd_requires = []
    }

    if $train_spamassassin {
        $spamassassin_args = ['--train-spamassassin']
        $spamassassin_requires = [Class['Spamassassin']]
    } else {
        $spamassassin_args = []
        $spamassassin_requires = []
    }

    file { '/usr/local/bin/train_mail_filters.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/profile/mail/vrts/train_mail_filters.py',
    }

    file { '/usr/local/sbin/rspamd_sqlite_backup.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/profile/mail/vrts/rspamd_sqlite_backup.py',
    }

    $prometheus_args = [
        '--prometheus-metrics-path',
        '/var/lib/prometheus/node.d/train_mail_filters.prom',
    ]
    $training_args = $spamassassin_args + $rspamd_args + $prometheus_args
    $training_command = "/usr/local/bin/train_mail_filters.py ${join($training_args, ' ')}"
    $training_and_backup_command = $train_rspamd.bool2str(
        "/bin/sh -c '${training_command} && ${rspamd_backup_command}'",
        $training_command
    )

    systemd::timer::job { 'vrts_train_mail_filters':
        ensure      => $training_ensure,
        user        => 'root',
        description => 'VRTS - train SpamAssassin and Rspamd filters',
        command     => $training_and_backup_command,
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:05:00'},
        require     => [
            File['/usr/local/bin/train_mail_filters.py'],
            File['/usr/local/sbin/rspamd_sqlite_backup.py'],
        ] + $spamassassin_requires + $rspamd_requires,
    }
}
