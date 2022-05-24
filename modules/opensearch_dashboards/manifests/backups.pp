# SPDX-License-Identifier: Apache-2.0
# == Class: opensearch_dashboards::backups
class opensearch_dashboards::backups (
  Wmflib::Ensure $ensure = 'present'
) {
  file { '/usr/local/sbin/run-dashboards-backup':
    ensure => $ensure,
    mode   => '0555',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/opensearch_dashboards/run-dashboards-backup.sh',
  }

  if ($ensure == 'present') {
    file { '/srv/backups':
      ensure => 'directory',
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    file { '/srv/backups/opensearch_dashboards':
      ensure  => 'directory',
      mode    => '0755',
      owner   => 'opensearch-dashboards',
      group   => 'opensearch-dashboards',
      require => File['/srv/backups']
    }
  }

  systemd::timer::job { 'run-dashboards-backup':
    ensure          => $ensure,
    description     => 'Dump OpenSearch Dashboards data',
    command         => '/usr/local/sbin/run-dashboards-backup',
    interval        => { 'start' => 'OnCalendar', 'interval' => '*-*-* 00:30:00' },
    user            => 'opensearch-dashboards',
    require         => [File['/usr/local/sbin/run-dashboards-backup'], Package['opensearch-dashboards']],
    logging_enabled => false,
  }
}
