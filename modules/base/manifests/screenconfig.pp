class base::screenconfig {
    if $::lsbdistid == 'Ubuntu' {
        file { '/root/.screenrc':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/base/screenrc',
        }
    }
}