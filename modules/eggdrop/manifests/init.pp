# sets up an instance of eggdrop
# the oldest IRC bot still in active development
#
# https://en.wikipedia.org/wiki/Eggdrop
# https://www.eggheads.org/
#
class eggdrop (
    $nick,
    $channel,
) {

    require_package('eggdrop', 'eggdrop-data')

    user { 'egguser':
        home       => '/usr/lib/eggdrop',
        groups     => 'egguser',
        managehome => true,
        system     => true,
    }

    file { '/srv/eggdrop':
        ensure => 'directory',
    }

    file { '/srv/eggdrop/eggdrop.conf':
        ensure  => 'present',
        owner   => 'egguser',
        group   => 'egguser',
        mode    => '0644',
        content => template('eggdrop/eggdrop.conf.erb')
    }
}

