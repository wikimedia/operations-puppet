# == Class: samplicator
#
# Install and manage Samplicator
#
# === Parameters
#
# === Parameters
#  [*port*]
#   Port to listen for datagrams on
#   Default: 2000
#  [*targets*]
#   List of "hostname(or IP)/port" to duplicate datagrams to

class samplicator(
  Array[String] $targets,
  Stdlib::Port $port = 2000,
  ) {

    require_package('samplicator')

    systemd::service { 'samplicator':
        content        => template('samplicator/samplicator.service.erb'),
        require        => Package['samplicator'],
        restart        => true,
        service_params => {
            ensure     => 'running', # lint:ignore:ensure_first_param
        },
    }

    nrpe::monitor_service { 'samplicator-process':
        description  => 'Samplicator process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C samplicate',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Netflow#Process',
    }
  }
