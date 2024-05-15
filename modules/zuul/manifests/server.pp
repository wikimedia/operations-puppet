# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2014 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: zuul::server
#
# === Parameters
#
# [*statsd_host*] IP/hostname of a statsd daemon to send metrics to. If unset
# (the default), nothing is ported.
#
# [*service_enable*]
#
# Passed to Service['zuul'] as 'enable'. Default: true.
#
# [*service_ensure*]
#
# Passed to systemd::service. either 'running' or 'stopped'.
# Default: 'running'.
#
class zuul::server (
    Stdlib::Host            $gerrit_server,
    String                  $gerrit_user,
    Stdlib::Host            $gearman_server,
    Boolean                 $gearman_server_start,
    String                  $url_pattern,
    Wmflib::Enable_Service  $service_enable     = true,
    Stdlib::Ensure::Service $service_ensure     = 'running',
    Optional[Stdlib::Host]  $statsd_host        = undef,
    Stdlib::HTTPUrl         $gerrit_baseurl     = 'https://gerrit.wikimedia.org/r',
    Integer                 $gerrit_event_delay = 5,
    Stdlib::HTTPUrl         $status_url         = "https://${facts['fqdn']}/zuul/status",
    Optional[Stdlib::Host]  $email_server       = undef,
    Stdlib::Port            $email_server_port  = 25,
    String                  $email_default_from = 'releng@lists.wikimedia.org',
    String                  $email_default_to   = 'qa-alerts@lists.wikimedia.org',
) {

    require zuul

    file { '/etc/default/zuul':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('zuul/zuul.default.erb'),
    }

    # Logging configuration
    # Modification done to this file can safely trigger a daemon
    # reload via the `zuul-reload` exect provided by the `zuul`
    # puppet module..
    file { '/etc/zuul/logging.conf':
        ensure => present,
        source => 'puppet:///modules/zuul/logging.conf',
        notify => Exec['zuul-reload'],
    }

    file { '/etc/zuul/gearman-logging.conf':
        ensure => present,
        owner  => 'zuul',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/zuul/gearman-logging.conf',
    }

    $zuul_role = 'server'
    $gearman_server_ip = ipresolve($gearman_server, 4)

    file { '/etc/zuul/zuul-server.conf':
        owner   => 'zuul',
        group   => 'root',
        mode    => '0400',
        content => template('zuul/zuul.conf.erb'),
        notify  => Exec['craft public zuul conf'],

    }

    # That was solely for zuul-gearman.py , the server has gear embedded.
    package { 'python3-gear':
        ensure => absent,
    }
    file { '/usr/local/bin/zuul-gearman.py':
        ensure  => absent,
    }

    # `gearadmin` to issue administrative commands
    # `gearman` a client and worker
    package { 'gearman-tools':
        ensure => present,
    }

    file { '/usr/local/bin/zuul-test-repo':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/zuul/zuul-test-repo.py',
    }

    # Additionally provide a publicly readeable configuration file
    exec { 'craft public zuul conf':
        cwd         => '/etc/zuul/',
        command     => '/bin/sed "s/apikey=.*/apikey=<REDACTED>/" /etc/zuul/zuul-server.conf > /etc/zuul/zuul.conf',
        refreshonly => true,
    }
    file { '/etc/zuul/zuul.conf':
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    file { '/etc/zuul/public.conf':
        ensure  => absent,
    }

    systemd::service { 'zuul':
        ensure         => 'present',
        content        => systemd_template('zuul'),
        restart        => false,
        service_params => {
            enable     => $service_enable,
            ensure     => $service_ensure,
            hasrestart => true,
        },
        require        => [
            File['/etc/default/zuul'],
            File['/etc/zuul/zuul-server.conf'],
            File['/etc/zuul/gearman-logging.conf'],
        ],
    }

    exec { 'zuul-reload':
        command     => '/bin/systemctl reload zuul',
        refreshonly => true,
    }
}
