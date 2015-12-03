
define security::access(
    $contents = undef,
    $source = undef,
    $priority = 50,
)
{
    include security::access::conf

    file { "/etc/security/access.conf.d/${priority}-${name}":
        ensure   => present,
        source   => $source,
        contents => $contents,
        owner    => 'root',
        group    => 'root',
        mode     => '0444',
        require  => File['/etc/security/access.conf.d'],
    }
}


class security::access::conf
{
    file { '/etc/security/access.conf.d':
        ensure  => directory,
        recurse => true,
        purge   => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        notify  => Exec['merge-access-conf'],
    }

    exec { 'merge-access-conf':
        refreshonly => true,
        cwd         => '/etc/security',
        command     => '/bin/cat access.conf.d/* >access.conf~ && mv access.conf~ access.conf',
    }

    security::pam::config {
        source => 'puppet:///modules/security/wikimedia-pam-access',
    }
}

