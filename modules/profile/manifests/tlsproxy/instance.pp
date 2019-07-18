# This defines the actual nginx daemon/instance which tlsproxy "sites" belong to
class profile::tlsproxy::instance(
    Boolean $websocket_support = hiera('cache::websocket_support', false),
    Boolean $lua_support = hiera('cache::lua_support', false),
    Boolean $nginx_tune_for_media = hiera('cache::tune_for_media', false),
    String $nginx_client_max_body_size = hiera('tlsproxy::nginx_client_max_body_size', '100m'),
    Boolean $bootstrap_protection = hiera('profile::tlsproxy::instance::bootstrap_protection', false),
    Enum['full', 'extras', 'light'] $nginx_variant = hiera('profile::tlsproxy::instance::nginx_variant', 'full'),
    Enum['strong', 'mid', 'compat'] $ssl_compatibility_mode = hiera('profile::tlsproxy::instance::ssl_compatibility_mode', 'compat')
) {
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

    $nginx_worker_connections = '131072'
    $nginx_ssl_conf = ssl_ciphersuite('nginx', $ssl_compatibility_mode)

    # If numa_networking is turned on, use interface_primary for NUMA hinting,
    # otherwise use 'lo' for this purpose.  Assumes NUMA data has "lo" interface
    # mapped to all cpu cores in the non-NUMA case.  The numa_iface variable is
    # in turn consumed by the systemd unit and config templates.
    if $::numa_networking != 'off' {
        $numa_iface = $facts['interface_primary']
    } else {
        $numa_iface = 'lo'
    }

    # If nginx will be installed on a system where apache is already
    # running, the postinst script will fail to start it with the default
    # configuration as port 80 is already in use. This is considered working
    # as designed by Debian, see
    #    https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=754407
    # However, we need the installation to complete correctly for puppet to
    # work as expected, hence we pre-install a configuration that will make
    # that possible. Note this file will be overwritten by puppet when
    # the nginx configuration gets installed properly.
    if $bootstrap_protection {
        exec { 'Dummy nginx.conf for installation':
            command => '/bin/mkdir -p /etc/nginx && /bin/echo -e "events { worker_connections 1; }\nhttp{ server{ listen 666; }}\n" > /etc/nginx/nginx.conf',
            creates => '/etc/nginx/nginx.conf',
            before  => Class['nginx'],
        }
    }

    class { 'nginx':
        variant => $nginx_variant,
        managed => false,
    }

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
        content => template('profile/tlsproxy/nginx.conf.erb'),
        tag     => 'nginx',
    }

    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/profile/tlsproxy/logrotate',
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
        content => template('profile/tlsproxy/nginx-numa.conf.erb'),
        before  => Class['nginx'],
        require => File[$sysd_nginx_dir],
    }

    file { $sysd_sec_conf:
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/profile/tlsproxy/nginx-security.conf',
        before  => Class['nginx'],
        require => File[$sysd_nginx_dir],
    }

    exec { 'systemd reload for nginx systemd fragments':
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
        subscribe   => [File[$sysd_numa_conf],File[$sysd_sec_conf]],
    }
}
