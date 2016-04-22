# Class: toollabs::bastion
#
# This role sets up an bastion/dev instance in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::bastion inherits toollabs {

    include gridengine::admin_host
    include gridengine::submit_host
    include toollabs::dev_environ
    include toollabs::exec_environ

    if $::operatingsystem == 'Ubuntu' {

        # misc group for on-the-fly classification
        # of expensive processes as opposed to kill
        # lint:ignore:arrow_alignment
        cgred::group {'throttle':
            config => {
                cpu    => {
                    'cpu.shares' => '128',
                },
                memory => {
                    'memory.limit_in_bytes' => '1152921504606846975',
                },
            },
        }

        # lint:ignore:arrow_alignment
        cgred::group {'shell':
            config => {
                memory => {
                    'memory.limit_in_bytes' => '2305843009213693951',
                },
            },
            rules  => [
                '*:/bin/sh             memory     /shell',
                '*:/bin/dash           memory     /shell',
                '*:/bin/bash           memory     /shell',
                '*:/usr/bin/zsh        memory     /shell',
                '*:/usr/bin/screen     memory     /shell',
                '*:/usr/bin/tmux       memory     /shell',
                '*:/usr/bin/lshell     memory     /shell',
            ],
        }

        # lint:ignore:arrow_alignment
        cgred::group {'user-daemons':
            config => {
                cpu    => {
                    'cpu.shares' => '512',
            },
                memory => {
                    'memory.limit_in_bytes' => '1152921504606846975',
            },
        },
            rules  => [
                '*:/usr/lib/openssh/sftp-server  cpu    /daemon',
                '*:/usr/lib/openssh/sftp-server  memory /daemon',
                '*:/usr/bin/mosh-server          memory /daemon',
            ],
        }

        # lint:ignore:arrow_alignment
        cgred::group {'scripts':
            config => {
                cpu    => {
                    'cpu.shares' => '512',
                },
                memory => {
                    'memory.limit_in_bytes' => '2305843009213693951',
                },
            },
            rules  => [
                '*:/usr/bin/ruby            cpu      /scripts',
                '*:/usr/bin/ruby            memory   /scripts',
                '*:/usr/bin/ruby1.9.1       cpu      /scripts',
                '*:/usr/bin/ruby1.9.3       memory   /scripts',
                '*:/usr/bin/python          cpu      /scripts',
                '*:/usr/bin/python          memory   /scripts',
                '*:/usr/bin/python2.7       cpu      /scripts',
                '*:/usr/bin/python2.7       memory   /scripts',
                '*:/usr/bin/python3         cpu      /scripts',
                '*:/usr/bin/python3         memory   /scripts',
                '*:/usr/bin/python3.4       cpu      /scripts',
                '*:/usr/bin/python3.4       memory   /scripts',
                '*:/usr/bin/perl            cpu      /scripts',
                '*:/usr/bin/perl            memory   /scripts',
                '*:/usr/bin/perl5.18.2      cpu      /scripts',
                '*:/usr/bin/perl5.18.2      memory   /scripts',
            ],
        }

        # lint:ignore:arrow_alignment
        cgred::group {'utilities':
            config => {
                cpu    => {
                    'cpu.shares' => '512',
                },
                memory => {
                    'memory.limit_in_bytes' => '2305843009213693951',
                },
            },
            rules  => [
                '*:/usr/bin/vim               memory  /utilities',
                '*:/usr/bin/vim.basic         memory  /utilities',
                '*:/usr/bin/vim.diff          memory  /utilities',
                '*:/usr/bin/vim.tiny          memory  /utilities',
                '*:/usr/bin/nano              memory  /utilities',
                '*:/bin/tar                   cpu     /utilities',
                '*:/bin/tar                   memory  /utilities',
                '*:/bin/gzip                  cpu     /utilities',
                '*:/bin/gzip                  memory  /utilities',
                '*:/bin/gzip                  memory  /utilities',
                '*:/usr/bin/nano              memory  /utilities',
                '*:/usr/bin/md5sum            cpu     /utilities',
                '*:/usr/bin/md5sum            memory  /utilities',
                '*:/usr/bin/sha1sum           cpu     /utilities',
                '*:/usr/bin/sha1sum           memory  /utilities',
                '*:/usr/bin/sha224sum         cpu     /utilities',
                '*:/usr/bin/sha224sum         memory  /utilities',
                '*:/usr/bin/sha256sum         cpu     /utilities',
                '*:/usr/bin/sha256sum         memory  /utilities',
                '*:/usr/bin/sha384sum         cpu     /utilities',
                '*:/usr/bin/sha384sum         memory  /utilities',
                '*:/usr/bin/sha512sum         cpu     /utilities',
                '*:/usr/bin/sha512sum         memory  /utilities',
                '*:/usr/bin/make              cpu     /utilities',
                '*:/usr/bin/make              memory  /utilities',
                '*:/usr/bin/gcc               cpu     /utilities',
                '*:/usr/bin/gcc               memory  /utilities',
                '*:/usr/bin/g++               cpu     /utilities',
                '*:/usr/bin/g++               memory  /utilities',
                '*:/usr/bin/gcc-4.8           cpu     /utilities',
                '*:/usr/bin/gcc-4.8           memory  /utilities',
                '*:/usr/bin/find              cpu     /utilities',
                '*:/usr/bin/find              memory  /utilities',
                '*:/usr/bin/top               cpu     /utilities',
                '*:/usr/bin/top               memory  /utilities',
                '*:/usr/bin/htop              cpu     /utilities',
                '*:/usr/bin/htop              memory  /utilities',
                '*:/usr/bin/sort              cpu     /utilities',
                '*:/usr/bin/sort              memory  /utilities',
                '*:/usr/bin/sed               cpu     /utilities',
                '*:/usr/bin/sed               memory  /utilities',
                '*:/usr/bin/mawk              cpu     /utilities',
                '*:/usr/bin/mawk              memory  /utilities',
                '*:/usr/bin/awk               cpu     /utilities',
                '*:/usr/bin/awk               memory  /utilities',
                '*:/usr/bin/wc                cpu     /utilities',
                '*:/usr/bin/wc                memory  /utilities',
            ],
        }
    }

    package { 'toollabs-webservice':
        ensure => latest,
    }

    package { 'mosh':
        ensure => present,
    }

    motd::script { 'bastion-banner':
        ensure => present,
        source => "puppet:///modules/toollabs/40-${::labsproject}-bastion-banner",
    }

    file {'/etc/security/limits.conf':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/limits.conf',
    }

    file { '/etc/ssh/ssh_config':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/submithost-ssh_config',
    }

    file { "${toollabs::store}/submithost-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$toollabs::store],
        content => "${::ipaddress}\n",
    }

    # Display tips.
    file { '/etc/profile.d/motd-tips.sh':
        ensure  => absent,
    }

    include ldap::role::config::labs
    $ldapconfig = $ldap::role::config::labs::ldapconfig

    $cron_host = hiera('active_cronrunner')
    file { '/usr/local/bin/crontab':
        ensure  => file,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('toollabs/crontab.erb'),
    }
    file { '/usr/local/bin/killgridjobs.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/gridscripts/killgridjobs.sh',
    }
}
