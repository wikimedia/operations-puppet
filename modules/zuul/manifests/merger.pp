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
    Enum['stopped', 'running', 'masked'] $ensure_service = 'running',
) {

    require ::zuul

    git::userconfig { '.gitconfig for Zuul merger':
        homedir  => '/var/lib/zuul',
        settings => {
            # Let us override git clone default settings set in the repository
            # $GIT_DIR/config when cloning
            'init'  => {
                'templateDir' => '/var/lib/zuul/git-template-dir',
            },
            'fetch' => {
                # Keep us in sync with Gerrit heads and tags
                #
                # The local branches accumulate and slow down zuul-merger when
                # it resets a repository. It recreates origin branches based on
                # local one which is kind of slow.  Since we don't care about
                # obsolete branches, get them pruned. (T220606).
                'prune'     => 'true',
                # Some repos might well delete tags and some definitely modify
                # them. Although we force fetch (T252310), it is good to keep
                # the state clean.
                'pruneTags' => 'true',
            }
        }
    }

    file { '/var/lib/zuul/git-template-dir':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    git::config { '/var/lib/zuul/git-template-dir/config':
        settings => {
            'core'  => {
                # No need for reflog which is the default for bare repos
                'logAllRefUpdates' => 'false',
            }
        }
    }

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
    file { '/var/lib/zuul/.ssh/id_rsa.pub':
        ensure    => present,
        owner     => 'zuul',
        group     => 'zuul',
        mode      => '0400',
        content   => secret("${gerrit_ssh_key_file}.pub"),
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

    if $ensure_service == 'masked' {
        systemd::mask { 'zuul-merge.service':  }
        $real_ensure_service = 'stopped'
    } else {
        $real_ensure_service = $ensure_service
    }

    systemd::service { 'zuul-merger':
        ensure         => 'present',
        content        => systemd_template('zuul-merger'),
        restart        => false,
        subscribe      => File['/etc/zuul/zuul-merger.conf'],
        service_params => {
                ensure => $real_ensure_service,
        },
        require        => [
            File['/etc/default/zuul-merger'],
            File['/etc/zuul/merger-logging.conf'],
            File['/etc/zuul/zuul-merger.conf'],
        ],
    }

    profile::auto_restarts::service { 'zuul-merger': }

    systemd::timer::job { 'zuul_repack':
        ensure       => present,
        user         => 'zuul',
        description  => 'Regular jobs for repacking heads and tags of repositories',
        command      => "/usr/bin/find ${git_dir} -maxdepth 3 -type d -name '.git' -exec /usr/bin/git --git-dir='{}' pack-refs --all \\;",
        send_mail    => true,
        send_mail_to => 'releng@lists.wikimedia.org',
        interval     => {'start' => 'OnCalendar', 'interval' => '*-*-* 4:07:00'},
        require      => File[$git_dir],
    }
}
