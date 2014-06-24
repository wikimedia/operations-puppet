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
    $statsd_host = '',
    $gerrit_server,
    $gerrit_user,
    $gearman_server,
    $gearman_server_start,
    $git_dir = '/var/lib/zuul/git',
    $jenkins_server,
    $jenkins_user,
    $jenkins_apikey,
    $url_pattern,
    $status_url = "https://${::fqdn}/zuul/status",
    $zuul_url = 'git://zuul.eqiad.wmnet',
) {

    file { '/var/run/zuul':
        ensure  => directory,
        owner   => 'jenkins',
        require => Package['jenkins'],
    }

    file { '/etc/init.d/zuul':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/zuul/zuul.init',
    }

    file { '/etc/default/zuul':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('zuul/zuul.default.erb'),
    }

    # TODO: We should put in  notify either Service['zuul'] or Exec['zuul-reload']
    #       at some point, but that still has some problems.
    file { '/etc/zuul/zuul.conf':
        ensure  => present,
        owner   => 'jenkins',
        mode    => '0400',
        content => template('zuul/zuul.conf.erb'),
        notify  => Exec['craft public zuul conf'],
        require => [
            File['/etc/zuul'],
            Package['jenkins'],
        ],
    }

    # Additionally provide a publicly readeable configuration file
    exec { 'craft public zuul conf':
        cwd         => '/etc/zuul/',
        command     => '/bin/sed "s/apikey=.*/apikey=<obfuscacated>/" /etc/zuul/zuul.conf > /etc/zuul/public.conf',
        refreshonly => true,
    }

    service { 'zuul':
        name       => 'zuul',
        enable     => true,
        hasrestart => true,
        require    => [
            File['/var/run/zuul'],
            File['/etc/init.d/zuul'],
            File['/etc/default/zuul'],
            File['/etc/zuul/zuul.conf'],
        ],
    }

    exec { 'zuul-reload':
        command     => '/etc/init.d/zuul reload',
        require     => File['/etc/init.d/zuul'],
        refreshonly => true,
    }
}
