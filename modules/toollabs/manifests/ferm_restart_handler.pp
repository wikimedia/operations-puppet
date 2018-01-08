# tldr; hook post ferm updates to let other interested
#       parties resync their iptables state.
# See: T182722
class toollabs::ferm_restart_handler{

    file {'/usr/local/sbin/ferm_restart_handler':
        source => 'puppet:///modules/toollabs/ferm_restart_handler.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # http://ferm.foo-projects.org/download/2.1/ferm.html#hooks
    # https://phabricator.wikimedia.org/T182722
    ferm::conf{'ferm_restart_handler':
        prio      => 00,
        content   => '@hook post "/usr/local/sbin/ferm_restart_handler";',
        subscribe => File['/usr/local/sbin/ferm_restart_handler'],
    }
}
