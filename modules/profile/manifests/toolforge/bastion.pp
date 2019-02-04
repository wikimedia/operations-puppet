# This profile sets up an bastion/dev instance in the Toolforge model.
class profile::toolforge::bastion(
    $active_cronrunner = hiera('profile::toolforge::active_cronrunner'),
    $master_host = hiera('k8s::master_host'),
    $etcd_hosts = hiera('flannel::etcd_hosts', [$master_host]),
){
    # Son of Grid Engine Configuration
    # admin_host???
    include profile::toolforge::shell_environ
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

    file { [
        '/usr/local/bin/webservice2',
        '/usr/local/bin/webservice',
    ]:
        ensure => link,
        target => '/usr/bin/webservice',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
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
