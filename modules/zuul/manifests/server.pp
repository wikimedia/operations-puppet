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
# **statsd_host** IP/hostname of a statsd daemon to send metrics to. If unset
# (the default), nothing is ported.
class zuul::server (
    $gerrit_server,
    $gerrit_user,
    $gearman_server,
    $gearman_server_start,
    $jenkins_server,
    $jenkins_user,
    $jenkins_apikey,
    $url_pattern,
    $statsd_host    = '',
    $gerrit_baseurl = 'https://gerrit.wikimedia.org/r',
    $status_url     = "https://${::fqdn}/zuul/status",
) {

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

    zuul::configfile { '/etc/zuul/zuul-server.conf':
        zuul_role => 'server',
        owner     => 'zuul',
        group     => 'root',
        mode      => '0400',
        notify    => Exec['craft public zuul conf'],
        require   => File['/etc/zuul'],
    }

    file { '/usr/local/bin/zuul-gearman.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['python-gear'],
        source  => 'puppet:///modules/zuul/zuul-gearman.py',
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

    service { 'zuul':
        name       => 'zuul',
        enable     => true,
        hasrestart => true,
        require    => [
            Package['zuul'],
            File['/etc/default/zuul'],
            File['/etc/zuul/zuul-server.conf'],
            File['/etc/zuul/gearman-logging.conf'],
        ],
    }

    exec { 'zuul-reload':
        command     => '/etc/init.d/zuul reload',
        require     => Package['zuul'],
        refreshonly => true,
    }
}
