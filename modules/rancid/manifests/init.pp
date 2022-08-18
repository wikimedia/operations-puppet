# SPDX-License-Identifier: Apache-2.0
# Really Awful Notorious CIsco config Differ
# @summary class to mange rancid
# @param active_server the FQDN of the active server
class rancid (
    Stdlib::Fqdn $active_server,
){

    package { 'rancid':
        ensure => present,
    }

    group { 'rancid':
        ensure => present,
        name   => 'rancid',
        system => true,
    }

    user { 'rancid':
        shell      => '/bin/sh',
        gid        => 'rancid',
        managehome => true,
        system     => true,
        home       => '/var/lib/rancid',
    }
    keyholder::agent { 'rancid':
        require        => Group['rancid'],
        trusted_groups => ['rancid'],
    }

    file {
        default:
            ensure => file,
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
        '/etc/rancid':
            ensure => directory;
        '/etc/rancid/rancid.conf':
            mode    => '0444',
            content => template('rancid/rancid.conf.erb');
        '/var/lib/rancid/bin/oglogin':
            source  => 'puppet:///modules/rancid/bin/oglogin';
        '/var/lib/rancid/bin/ograncid':
            source  => 'puppet:///modules/rancid/bin/ograncid';
        '/var/lib/rancid/bin/ssh-serial-console-wrapper':
            source  => 'puppet:///modules/rancid/bin/ssh-serial-console-wrapper';
    }
    file {
        default:
            ensure => file,
            owner  => 'rancid',
            group  => 'rancid';
        '/var/lib/rancid':
            ensure => directory,
            mode   => '0750';
        '/var/lib/rancid/.cloginrc':
            mode    => '0440',
            content => template('rancid/cloginrc.erb');
        '/var/lib/rancid/.gitconfig':
            mode    => '0440',
            content => template('rancid/gitconfig.erb');
        '/var/lib/rancid/.ssh':
            ensure => directory,
            mode   => '0700';
        '/var/lib/rancid/.ssh/config':
            mode   => '0644',
            source => 'puppet:///modules/rancid/ssh_config';
        '/var/lib/rancid/core':
            ensure  => directory,
            recurse => remote,
            mode    => '0774',
            source  => 'puppet:///modules/rancid/core';
        '/var/lib/rancid/core/configs':
            ensure => directory,
            mode   => '0774';
    }

    file_line { 'opengear_script':
      path => '/etc/rancid/rancid.types.base',
      line => 'opengear;script;ograncid',
    }

    file_line { 'opengear_login':
      path => '/etc/rancid/rancid.types.base',
      line => 'opengear;login;oglogin',
    }

    $job_ensure = ($active_server == $facts['networking']['fqdn']).bool2str('present', 'absent')

    systemd::timer::job { 'rancid-differ':
        ensure             => $job_ensure,
        user               => 'rancid',
        description        => 'run rancid-run',
        environment        => { 'SSH_AUTH_SOCK' => '/run/keyholder/proxy.sock' },
        command            => '/usr/lib/rancid/bin/rancid-run',
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '1h'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }

    systemd::timer::job { 'rancid-clean-logs':
        ensure             => $job_ensure,
        user               => 'rancid',
        description        => 'clean rancid logs',
        command            => '/usr/bin/find /var/log/rancid -type f -mtime +2 -exec rm {} \;',
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 23:50:0'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }
}
