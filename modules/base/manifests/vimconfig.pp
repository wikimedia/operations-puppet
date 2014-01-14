class base::vimconfig {
    file { '/etc/vim/vimrc.local':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/vimconfig/vimrc.local',
    }

    if $::lsbdistid == 'Ubuntu' {
        # Joe is for pussies
        file { '/etc/alternatives/editor':
            ensure => link,
            target => '/usr/bin/vim',
        }
    }
}
