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
    $url_pattern,
    $gerrit_baseurl = 'https://gerrit.wikimedia.org/r',
    $git_dir        = '/var/lib/zuul/git',
    $git_email      = "zuul-merger@${::hostname}",
    $git_name       = 'Wikimedia Zuul Merger',
    $status_url     = "https://${::fqdn}/zuul/status",
    $zuul_url       = 'git://zuul.eqiad.wmnet',
) {

    require ::zuul

    file { $git_dir:
        ensure => directory,
        owner  => 'zuul',
    }

    # Configuration file for the zuul merger
    zuul::configfile { '/etc/zuul/zuul-merger.conf':
        zuul_role => 'merger',
        owner     => 'root',
        group     => 'root',
        mode      => '0444',
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

    service { 'zuul-merger':
        name       => 'zuul-merger',
        enable     => true,
        hasrestart => true,
        subscribe  => File['/etc/zuul/zuul-merger.conf'],
        require    => [
            File['/etc/default/zuul-merger'],
            File['/etc/zuul/merger-logging.conf'],
            File['/etc/zuul/zuul-merger.conf'],
        ],
    }

    cron { 'zuul_repack':
        user        => 'zuul',
        hour        => '4',
        minute      => '7',
        command     => "MAILTO='jenkins-bot@wikimedia.org' find ${git_dir} -maxdepth 3 -type d -name '.git' -exec git --git-dir='{}' pack-refs --all \\;",
        environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
        require     => File[$git_dir],
    }
}
