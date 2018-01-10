# tldr; hook post ferm updates to let other interested
#       parties resync their iptables state.
# See: T182722
# http://ferm.foo-projects.org/download/2.1/ferm.html#hooks

class toollabs::ferm_handlers{

    file {'/usr/local/sbin/ferm_restart_handler':
        ensure => 'absent',
    }

    file {'/usr/local/sbin/ferm_pre_handler':
        source => 'puppet:///modules/toollabs/ferm_pre_handler.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file {'/usr/local/sbin/ferm_post_handler':
        source => 'puppet:///modules/toollabs/ferm_post_handler.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    ferm::conf{'ferm_pre_handler':
        prio      => '00',
        content   => '@hook post "/usr/local/sbin/ferm_pre_handler";',
        subscribe => File['/usr/local/sbin/ferm_pre_handler'],
    }

    ferm::conf{'ferm_post_handler':
        prio      => '00',
        content   => '@hook post "/usr/local/sbin/ferm_post_handler";',
        subscribe => File['/usr/local/sbin/ferm_post_handler'],
    }
}
