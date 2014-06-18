class mha::node {
    package { 'mha4mysql-node':
        ensure => latest,
    }

    file { [ '/home/mysql', '/home/mysql/.ssh' ]:
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0700',
        require => User['mysql'],
    }

    file { '/home/mysql/.ssh/mysql.key':
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0400',
        source => 'puppet:///private/ssh/mysql/mysql.key',
    }

    ssh_authorized_key { 'mha4mysql':
            ensure => present,
            user   => 'mysql',
            type   => 'ssh-rsa',
            key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDryVraiGfd0eQzV0QB/xXvgiPvpp8qt/BEqT9xWpohPNC1MevM+SMGmpimCLyvv35JDmz1DiJwJf72GKakDqWdbp/pBHitr0VV3eANpLyYiDTWir75SEF9F/WxkRTbEe/tErJc0tsksVGIm+36r3eHrrz68AkJJZVhcQMMXPx6Ye1NIy5qJ/i7cSSAxkanHlXiX+lnGMIxYUKuiVVl7kxrGDAvaLeszZKdYn8WkMH32MuL/M66ff9vBY7pGGM8MubjGMxL878hpimhTrLcmay7l4nuAMW6UUnkqufx6ArT80RWDWz5woFvyheBdVDnQZI06cJzj3WG6rWt8eG/A1SL',
    }
}

class mha::manager inherits role::coredb::config {
    include mha::node
    include passwords::misc::scripts

    $mysql_root_pass = $passwords::misc::scripts::mysql_root_pass
    $mysql_repl_pass = $passwords::misc::scripts::mysql_repl_pass

    package { 'mha4mysql-manager':
        ensure => latest,
    }

    file { '/etc/mha':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    file { '/etc/mha/primary_site':
        content => "${::mw_primary}\n",
    }

    file { '/usr/local/bin/master_ip_online_change':
        source => 'puppet:///files/mha/master_ip_online_change',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/mha_site_switch':
        source => 'puppet:///files/mha/mha_site_switch',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }

    $shardlist = inline_template('<%= topology.keys.join(',') %>')
    $shards    = split($shardlist, ',')

    define mha_shard_config(
        $shard  = {},
        $site   = '',
        $altsite= '',
) {
        file { "/etc/mha/${name}.cnf":
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => template('mha/local.erb'),
            require => File['/etc/mha'],
        }
    }

    define mha_dc_switch( $shard={} ) {
        file { "/etc/mha/${name}-dc.cnf":
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => template('mha/siteswitch.erb'),
            require => File['/etc/mha'],
        }
    }

    define mha_coredb_config( $topology={} ) {
        $shard = $topology[$name]
        if $shard['primary_site'] and $shard['primary_site'] != 'both' {
            # eqiad
            mha_shard_config { "${name}-eqiad":
                shard   => $shard,
                site    => 'eqiad',
                altsite => 'pmtpa',
            }
            # pmtpa
            mha_shard_config { "${name}-pmtpa":
                shard   => $shard,
                site    => 'pmtpa',
                altsite => 'eqiad',
            }
            # dc switch
            mha_dc_switch { $name:
                shard => $shard,
            }

        }
    }

    mha_coredb_config { $shards: topology => $topology }
}
