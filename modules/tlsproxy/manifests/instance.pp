# This defines the actual nginx daemon/instance which tlsproxy "sites" belong to
class tlsproxy::instance {
    # Enable client/server TCP Fast Open (TFO)
    #
    # The values (bitmap) are:
    # 1: Enables sending data in the opening SYN on the client w/ MSG_FASTOPEN
    # 2: Enables TCP Fast Open on the server side, i.e., allowing data in
    #    a SYN packet to be accepted and passed to the application before the
    #    3-way hand shake finishes
    #
    # Note that, despite the name, this setting is *not* IPv4-specific. TFO
    # support will be enabled on both IPv4 and IPv6
    sysctl::parameters { 'TCP Fast Open':
        values => {
            'net.ipv4.tcp_fastopen' => 3,
        },
    }

    $websocket_support = hiera('cache::websocket_support', false)
    $lua_support = hiera('cache::lua_support', false)
    $nginx_worker_connections = '131072'
    $nginx_ssl_conf = ssl_ciphersuite('nginx', 'compat')
    $nginx_tune_for_media = hiera('cache::tune_for_media', false)
    $nginx_client_max_body_size = hiera('tlsproxy::nginx_client_max_body_size', '100m')

    # If numa_networking is turned on, use interface_primary for NUMA hinting,
    # otherwise use 'lo' for this purpose.  Assumes NUMA data has "lo" interface
    # mapped to all cpu cores in the non-NUMA case.  The numa_iface variable is
    # in turn consumed by the systemd unit and config templates.
    if $::numa_networking {
        $numa_iface = $facts['interface_primary']
    } else {
        $numa_iface = 'lo'
    }

    class { 'nginx': managed => false, }

    if $lua_support {
        require_package([ 'libnginx-mod-http-lua', 'libnginx-mod-http-ndk' ])

        # Directory for Lua modules
        file { '/etc/nginx/lua/':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    file { '/etc/nginx/nginx.conf':
        content => template('tlsproxy/nginx.conf.erb'),
        tag     => 'nginx',
    }

    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/tlsproxy/logrotate',
        tag    => 'nginx',
    }

    # systemd unit fragments for NUMA and security
    $sysd_nginx_dir = '/etc/systemd/system/nginx.service.d'
    $sysd_numa_conf = "${sysd_nginx_dir}/numa.conf"
    $sysd_sec_conf = "${sysd_nginx_dir}/security.conf"

    file { $sysd_nginx_dir:
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { $sysd_numa_conf:
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('tlsproxy/nginx-numa.conf.erb'),
        before  => Class['nginx'],
        require => File[$sysd_nginx_dir],
    }

    file { $sysd_sec_conf:
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/tlsproxy/nginx-security.conf',
        before  => Class['nginx'],
        require => File[$sysd_nginx_dir],
    }

    exec { 'systemd reload for nginx systemd fragments':
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
        subscribe   => [File[$sysd_numa_conf],File[$sysd_sec_conf]],
    }
}
