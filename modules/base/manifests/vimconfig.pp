class base::vimconfig {
    # This is provided for some reason by wikimedia-base. We ensure it purged
    # but do not remove this resource until wikimedia-base no longer manages
    # that file #RT 7618 or wikimedia-base no longer exists
    file { '/etc/vim/vimrc.local':
        ensure => absent,
    }

    if $::lsbdistid == 'Ubuntu' {
        # Joe is for pussies
        file { '/etc/alternatives/editor':
            ensure => link,
            target => '/usr/bin/vim',
        }
    }
}
