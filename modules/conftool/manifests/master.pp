class conftool::master($sync_dir = '/etc/conftool/data') {

    require conftool

    require ::puppetmaster::base_repo

    file { '/etc/conftool/data':
        ensure => link,
        target => "${::puppet::base_repo::gitdir}/operations/puppet/conftool-data",
        force  => true,
        before => File['/usr/local/bin/conftool-merge'],
    }

    file { '/usr/local/bin/conftool-merge':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0500',
        content => template('conftool/conftool-merge.erb')
    }

}
