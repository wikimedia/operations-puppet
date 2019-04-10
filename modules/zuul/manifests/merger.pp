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

# == Class: zuul::merger
#
class zuul::merger (
    $gearman_server,
    $gerrit_server,
    $gerrit_user,
    $gerrit_ssh_key_file,
    $gerrit_baseurl = 'https://gerrit.wikimedia.org/r',
    $git_dir        = '/var/lib/zuul/git',
    $git_email      = "zuul-merger@${::hostname}",
    $git_name       = 'Wikimedia Zuul Merger',
    $zuul_url       = $::fqdn,
) {

    require ::zuul

    exec { 'zuul merger recursive mkdir of git_dir':
        command => "/bin/mkdir -p ${git_dir}",
        creates => $git_dir,
    }

    file { $git_dir:
        ensure  => directory,
        owner   => 'zuul',
        require => Exec['zuul merger recursive mkdir of git_dir'],
    }

    file { '/var/lib/zuul/.ssh':
        ensure => 'directory',
        owner  => 'zuul',
        group  => 'zuul',
        mode   => '0700',
    }

    file { '/var/lib/zuul/.ssh/id_rsa':
        ensure    => present,
        owner     => 'zuul',
        group     => 'zuul',
        mode      => '0400',
        content   => secret($gerrit_ssh_key_file),
        show_diff => false,
        require   => [
            User['zuul'],
            File['/var/lib/zuul/.ssh'],
        ],
    }

    # Configuration file for the zuul merger
    $zuul_role = 'merger'
    file { '/etc/zuul/zuul-merger.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('zuul/zuul.conf.erb'),
    }

    file { '/etc/default/zuul-merger':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('zuul/zuul-merger.default.erb'),
        notify  => Service['zuul-merger'],
    }

    file { '/etc/zuul/merger-logging.conf':
        ensure => present,
        source => 'puppet:///modules/zuul/merger-logging.conf',
    }

    systemd::service { 'zuul-merger':
        ensure    => present,
        content   => systemd_template('zuul-merger'),
        restart   => false,
        subscribe => File['/etc/zuul/zuul-merger.conf'],
        require   => [
            File['/etc/default/zuul-merger'],
            File['/etc/zuul/merger-logging.conf'],
            File['/etc/zuul/zuul-merger.conf'],
        ],
    }

    base::service_auto_restart { 'zuul-merger': }

    cron { 'zuul_repack':
        user        => 'zuul',
        hour        => '4',
        minute      => '7',
        command     => "find ${git_dir} -maxdepth 3 -type d -name '.git' -exec git --git-dir='{}' pack-refs --all \\;",
        environment => [
            'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
            'MAILTO="jenkins-bot@wikimedia.org"',
        ],
        require     => File[$git_dir],
    }
}
