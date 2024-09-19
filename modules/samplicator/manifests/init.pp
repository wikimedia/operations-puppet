# SPDX-License-Identifier: Apache-2.0
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
  Integer $recvbuf = 50*1024*1024,
  ) {

    ensure_packages('samplicator')

    systemd::service { 'samplicator':
        content        => template('samplicator/samplicator.service.erb'),
        require        => Package['samplicator'],
        restart        => true,
        service_params => {
            ensure     => 'running', # lint:ignore:ensure_first_param
        },
    }

    profile::auto_restarts::service { 'samplicator': }
  }
