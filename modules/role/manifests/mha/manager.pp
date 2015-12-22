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
                altsite => 'codfw',
            }
            # codfw
            mha_shard_config { "${name}-codfw":
                shard   => $shard,
                site    => 'codfw',
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
