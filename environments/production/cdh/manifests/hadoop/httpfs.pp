# == Class cdh::hadoop::httpfs
# Installs hadoop-httpfs and starts up an httpfs server.
# Make sure the httpfs_enabled parameter is true when you
# include cdh::hadoop if you want to include this class.
#
# == Parameters
# $signature_secret       - secret to sign HttpFS hadoop-auth cookie
# $heapsize               - -Xmx in MB to configure Catalina with.  Default: undef
class cdh::hadoop::httpfs(
        $signature_secret = 'hadoop httpfs secret',
        $heapsize         = undef,
)
{
    Class['cdh::hadoop'] -> Class['cdh::hadoop::httpfs']

    package { 'hadoop-httpfs':
        ensure => 'installed',
    }

    $config_directory = "/etc/hadoop-httpfs/conf.${cdh::hadoop::cluster_name}"
    # Create the $cluster_name based $config_directory.
    file { $config_directory:
        ensure  => 'directory',
        require => Package['hadoop-httpfs'],
    }
    cdh::alternative { 'hadoop-httpfs-conf':
        link => '/etc/hadoop-httpfs/conf',
        path => $config_directory,
    }

    file { "${config_directory}/httpfs-site.xml":
        content => template('cdh/hadoop/httpfs-site.xml.erb'),
        require => Package['hadoop-httpfs'],
    }
    file { "${config_directory}/httpfs-log4j.properties":
        content => template('cdh/hadoop/httpfs-log4j.properties.erb'),
        require => Package['hadoop-httpfs'],
    }
    file { "${config_directory}/httpfs-signature.secret":
        content => $signature_secret,
        owner   => 'httpfs',
        group   => 'httpfs',
        mode    => '0440',
        require => Package['hadoop-httpfs'],
    }

    service { 'hadoop-httpfs':
        ensure     => 'running',
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        subscribe  => [
            File["${config_directory}/httpfs-site.xml"],
            File["${config_directory}/httpfs-log4j.properties"],
            File["${config_directory}/httpfs-signature.secret"],
        ],
        require    => Package['hadoop-httpfs'],
    }
}
