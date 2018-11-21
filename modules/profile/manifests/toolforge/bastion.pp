# This profile sets up an bastion/dev instance in the Toolforge model.
#
# [*nproc]
#  limits.conf nproc
#

class profile::toolforge::bastion(
    $nproc = hiera('profile::toolforge::bastion::nproc',30),
    $active_cronrunner = hiera('profile::toolforge::active_cronrunner'),
    $master_host = hiera('k8s::master_host'),
    $etcd_hosts = hiera('flannel::etcd_hosts', [$master_host]),
){
    # Son of Grid Engine Configuration
    # admin_host???
    class {'::sonofgridengine::submit_host': }
    include profile::toolforge::dev_environ
    include profile::toolforge::grid::exec_environ

    file { '/etc/toollabs-cronhost':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $active_cronrunner,
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
        source => 'puppet:///modules/profile/toolforge/gridscripts/killgridjobs.sh',
    }

    file { '/usr/local/sbin/exec-manage':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/profile/toolforge/exec-manage',
    }

    file { '/usr/local/sbin/qstat-full':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/profile/toolforge/qstat-full',
    }

    file { "${profile::toolforge::grid::base::store}/submithost-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$profile::toolforge::grid::base::store],
        content => "${::ipaddress}\n",
    }

    # General SSH Use Configuration
    package { 'toollabs-webservice':
        ensure => latest,
    }

    motd::script { 'bastion-banner':
        ensure => present,
        source => "puppet:///modules/profile/toolforge/40-${::labsproject}-bastion-banner.sh",
    }

    # Display tips.
    file { '/etc/profile.d/motd-tips.sh':
        ensure  => absent,
    }

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

    # TODO: port this junk to systemd! -- See T210098
    # if os_version('debian == stretch') {

    #     cgred::group {'shell':
    #         order  => '01',
    #         config => {
    #             memory => {
    #                 'memory.limit_in_bytes' => '4611686018427387903',
    #             },
    #         },
    #         rules  => [
    #             '*:/bin/sh             memory     /shell',
    #             '*:/bin/dash           memory     /shell',
    #             '*:/bin/bash           memory     /shell',
    #             '*:/usr/bin/zsh        memory     /shell',
    #             '*:/usr/bin/screen     memory     /shell',
    #             '*:/usr/bin/tmux       memory     /shell',
    #             '*:/usr/bin/lshell     memory     /shell',
    #         ],
    #     }

    #     # misc group for on-the-fly classification
    #     # of expensive processes as opposed to kill
    #     cgred::group {'throttle':
    #         config => {
    #             cpu    => {
    #                 'cpu.shares' => '128',
    #             },
    #             memory => {
    #                 'memory.limit_in_bytes' => '1152921504606846975',
    #             },
    #         },
    #     }

    #     cgred::group {'user-daemons':
    #         config => {
    #             cpu    => {
    #                 'cpu.shares' => '512',
    #         },
    #             memory => {
    #                 'memory.limit_in_bytes' => '1152921504606846975',
    #         },
    #     },
    #         rules  => [
    #             '*:/usr/bin/mosh-server             memory /daemon',
    #             '*:/usr/lib/openssh/sftp-server     cpu    /daemon',
    #             '%                                  memory /daemon',
    #         ],
    #     }

    #     cgred::group {'scripts':
    #         config => {
    #             cpu    => {
    #                 'cpu.shares' => '512',
    #             },
    #             memory => {
    #                 'memory.limit_in_bytes' => '2305843009213693951',
    #             },
    #         },
    #         rules  => [
    #             '*:/usr/bin/php             cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/ruby            cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/ruby2.3       cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/python          cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/python2.7       cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/python3         cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/python3.5       cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/perl            cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/perl5.24.1      cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/tclsh8.5        cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/tclsh8.6        cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/usr/bin/tclsh8.7        cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/shared/bin/node         cpu      /scripts',
    #             '%                          memory   /scripts',
    #             '*:/data/project/shared/tcl/bin/tclsh8.7        cpu      /scripts',
    #             '%                                              memory   /scripts',
    #         ],
    #     }

    #     cgred::group {'utilities':
    #         config => {
    #             cpu    => {
    #                 'cpu.shares' => '512',
    #             },
    #             memory => {
    #                 'memory.limit_in_bytes' => '2305843009213693951',
    #             },
    #         },
    #         rules  => [
    #             '*:/usr/bin/vim               memory  /utilities',
    #             '*:/usr/bin/vim.basic         memory  /utilities',
    #             '*:/usr/bin/vim.diff          memory  /utilities',
    #             '*:/usr/bin/vim.tiny          memory  /utilities',
    #             '*:/usr/bin/nano              memory  /utilities',
    #             '*:/usr/bin/unzip             cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/bin/tar                   cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/bin/bzip2                  cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/bin/gzip                  cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/md5sum            cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/sha1sum           cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/sha224sum         cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/sha256sum         cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/sha384sum         cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/sha512sum         cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/make              cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/gcc               cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/g++               cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/find              cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/top               cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/htop              cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/sort              cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/sed               cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/mawk              cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/awk               cpu     /utilities',
    #             '%                            memory  /utilities',
    #             '*:/usr/bin/wc                cpu     /utilities',
    #             '%                            memory  /utilities',
    #         ],
    #     }
    # }

    package { 'mosh':
        ensure => present,
    }

    file {'/etc/security/limits.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/limits.conf.erb'),
    }

    file { '/etc/ssh/ssh_config':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/toolforge/submithost-ssh_config',
    }

    # Kubernetes Configuration - See T209627
    if os_version('ubuntu trusty') or os_version('debian jessie'){
        $etcd_url = join(prefix(suffix($etcd_hosts, ':2379'), 'https://'), ',')

        if os_version('debian == stretch') {
            $docker_version = '1.12.6-0~debian-jessie' # The stretch repo appears to have a jessie version?

            class { '::profile::docker::engine':
                settings        => {
                    'iptables'     => false,
                    'ip-masq'      => false,
                    'live-restore' => true,
                },
                version         => $docker_version,
                declare_service => false,
            }
        }


        ferm::service { 'flannel-vxlan':
            proto => udp,
            port  => 8472,
        }

        class { '::k8s::flannel':
            etcd_endpoints => $etcd_url,
        }

        class { '::k8s::infrastructure_config':
            master_host => $master_host,
        }

        class { '::k8s::proxy':
            master_host => $master_host,
        }
    }

    require_package('kubernetes-client')
}
