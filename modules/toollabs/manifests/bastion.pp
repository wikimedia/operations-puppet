# This role sets up an bastion/dev instance in the Tool Labs model.
#
# [*nproc]
#  limits.conf nproc
#

class toollabs::bastion(
        $nproc = 30,
    ) inherits toollabs {

    include ::gridengine::admin_host
    include ::gridengine::submit_host
    include ::toollabs::dev_environ
    include ::toollabs::exec_environ

    if os_version('ubuntu trusty') {

        cgred::group {'shell':
            order  => '01',
            config => {
                memory => {
                    'memory.limit_in_bytes' => '4611686018427387903',
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

        # misc group for on-the-fly classification
        # of expensive processes as opposed to kill
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
                '*:/usr/bin/mosh-server             memory /daemon',
                '*:/usr/lib/openssh/sftp-server     cpu    /daemon',
                '%                                  memory /daemon',
            ],
        }

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
                '*:/usr/bin/php             cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/ruby            cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/ruby1.9.1       cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/python          cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/python2.7       cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/python3         cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/python3.4       cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/perl            cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/perl5.18.2      cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/tclsh8.5        cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/tclsh8.6        cpu      /scripts',
                '%                          memory   /scripts',
                '*:/usr/bin/tclsh8.7        cpu      /scripts',
                '%                          memory   /scripts',
                '*:/shared/bin/node         cpu      /scripts',
                '%                          memory   /scripts',
                '*:/data/project/shared/tcl/bin/tclsh8.7        cpu      /scripts',
                '%                                              memory   /scripts',
            ],
        }

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
                '*:/usr/bin/unzip             cpu     /utilities',
                '%                            memory  /utilities',
                '*:/bin/tar                   cpu     /utilities',
                '%                            memory  /utilities',
                '*:/bin/bzip2                  cpu     /utilities',
                '%                            memory  /utilities',
                '*:/bin/gzip                  cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/md5sum            cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/sha1sum           cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/sha224sum         cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/sha256sum         cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/sha384sum         cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/sha512sum         cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/make              cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/gcc               cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/g++               cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/gcc-4.8           cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/find              cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/top               cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/htop              cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/sort              cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/sed               cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/mawk              cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/awk               cpu     /utilities',
                '%                            memory  /utilities',
                '*:/usr/bin/wc                cpu     /utilities',
                '%                            memory  /utilities',
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
        source => "puppet:///modules/toollabs/40-${::labsproject}-bastion-banner.sh",
    }

    file {'/etc/security/limits.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('toollabs/limits.conf.erb'),
    }

    file { '/etc/ssh/ssh_config':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
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

    include ::ldap::config::labs
    $ldapconfig = $ldap::config::labs::ldapconfig

    file { '/etc/toollabs-cronhost':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => hiera('active_cronrunner'),
    }
    file { '/usr/local/bin/crontab':
        ensure  => 'link',
        target  => '/usr/bin/oge-crontab',
        require => Package['misctools'],
    }

    file { '/usr/local/bin/killgridjobs.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/gridscripts/killgridjobs.sh',
    }

    file { '/usr/local/sbin/exec-manage':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/toollabs/exec-manage',
    }

    file { '/usr/local/sbin/qstat-full':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/toollabs/qstat-full',
    }
}
