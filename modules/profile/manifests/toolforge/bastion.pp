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


    package { 'mosh':
        ensure => present,
    }

    # we need systemd >= 239 for resource control using the user-.slice trick
    # this version is provied in stretch-backports
    package { 'systemd':
        ensure          => present,
        install_options => ['-t', 'stretch-backports'],
    }

    systemd::unit { 'user-.slice':
        ensure   => present,
        content  => file('profile/toolforge/bastion-user-resource-control.conf'),
        override => true,
    }

    systemd::unit { 'user-0.slice':
        ensure   => present,
        content  => file('profile/toolforge/bastion-root-resource-control.conf'),
        override => true,
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
