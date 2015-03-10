# == Define limn::instance
# Starts up a Limn Server instance.
#
# == Parameters:
# $port           - Listen port for Limn instance.  Default: 8081
# $environment    - Node environment.  Default: production
# $base_directory - Limn install base directory.  Default: /usr/local/share/limn
# $var_directory  - Limn instance var directory.  Limn datafiles live here.  Default: /var/lib/limn/$name
# $log_file       - Limn instance log file.  Default: /var/log/limn/limn-$name.log
# $ensure         - present|absent.  Default: present
#
define limn::instance (
    $port           = '8081',
    $environment    = 'production',
    $base_directory = '/usr/local/share/limn',
    $var_directory  = "/var/lib/limn/${name}",
    $log_file       = "/var/log/limn/limn-${name}.log",
    $ensure         = present
){
    require limn

    validate_ensure($ensure)

    if !defined(File[$base_directory]) {
        file { $base_directory:
            ensure => directory,
            owner  => $limn::user,
            group  => $limn::group,
            mode   => '0775',
        }
    }

    file { $var_directory:
        ensure => directory,
        owner  => $limn::user,
        group  => $limn::group,
        mode   => '0775',
    }

    # The upstart init conf will start server.co
    # logging to this file.
    file { $log_file:
        ensure => file,
        owner  => $limn::user,
        group  => $limn::group,
        mode   => '0775',
    }

    # symlink $base_directory/var/{css,js,vendor}
    # in $var_directory
    file { "${var_directory}/css":
        ensure => ensure_link($ensure),
        target => "${base_directory}/var/css",
    }
    file { "${var_directory}/js":
    ensure => ensure_link($ensure),
    target => "${base_directory}/var/js",
    }
    file { "${var_directory}/vendor":
        ensure => ensure_link($ensure),
        target => "${base_directory}/var/vendor",
    }

    # Install an upstart init file for this limn server instance.
    file { "/etc/init/limn-${name}.conf":
        ensure    => $ensure,
        content   => template('limn/init-limn.conf.erb'),
        owner     => 'root',
        group     => 'root',
        mode      => '0444',
        require   => [File[$var_directory], File[$log_file]],
    }

    # Symlink an /etc/init.d script to upstart-job
    # for SysV compatibility.
    $sysv_ensure = $ensure ? {
        present   => link,
        default   => absent,
    }
    file { "/etc/init.d/limn-${name}":
        ensure  => $sysv_ensure,
        target  => '/lib/init/upstart-job',
        require => File["/etc/init/limn-${name}.conf"],
    }

    # Start the service.
    service { "limn-${name}":
        ensure     => ensure_service($ensure),
        provider   => 'upstart',
        subscribe  => File["/etc/init/limn-${name}.conf"],
    }
}
