# == Class dsh::config
#
# Sets up dsh config files alone, without actually
# setting up dsh. Useful primarily for monitoring
class dsh::config (
    $scap_proxies = [],
    $parsoid = [],
    $mediawiki_install = [],
){
    file { '/etc/dsh':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { '/etc/dsh/dsh.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/dsh/dsh.conf',
        require => File['/etc/dsh'],
    }

    file { '/etc/dsh/group':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/dsh'],
    }

    dsh::group { 'scap-proxies':
        entries => $scap_proxies,
    }

    dsh::group { 'parsoid':
        entries => $parsoid,
    }

    dsh::group { 'mediawiki-install':
        entries => $mediawiki_install,
    }
}
