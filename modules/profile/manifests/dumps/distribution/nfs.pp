# Set up NFS Server for the public dumps servers
# Firewall rules are managed separately through profile::wmcs::nfs::ferm

class profile::dumps::distribution::nfs (
    $nfs_clients = hiera('profile::dumps::distribution::nfs_clients')
  ) {

    require_package('nfs-kernel-server', 'nfs-common', 'rpcbind')

    file { '/etc/default/nfs-common':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/dumps/distribution/nfs-common',
    }

    file { '/etc/default/nfs-kernel-server':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/dumps/distribution/nfs-kernel-server',
    }

    file { '/etc/modprobe.d/nfs-lockd.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => 'options lockd nlm_udpport=32768 nlm_tcpport=32769',
    }

    file { '/etc/exports':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dumps/distribution/nfs-exports.erb'),
        require => Package['nfs-kernel-server'],
    }

    # Manage state manually
    service { 'nfs-kernel-server':
        enable  => false,
        require => Package['nfs-kernel-server'],
    }

    ferm::service { 'labstore_analytics_nfs_portmapper_udp':
        proto  => 'udp',
        port   => '111',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service { 'labstore_analytics_nfs_portmapper_tcp':
        proto  => 'tcp',
        port   => '111',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service { 'labstore_analytics_nfs_nfs_service':
        proto  => 'tcp',
        port   => '2049',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service { 'labstore_analytics_nfs_rpc_statd_tcp':
        proto  => 'tcp',
        port   => '55659',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service { 'labstore_analytics_nfs_rpc_statd_udp':
        proto  => 'udp',
        port   => '55659',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service { 'labstore_analytics_nfs_rpc_mountd':
        proto  => 'tcp',
        port   => '38466',
        srange => '$ANALYTICS_NETWORKS',
    }

    monitoring::service { 'nfs':
        description   => 'NFS',
        check_command => 'check_tcp!2049',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }
}
