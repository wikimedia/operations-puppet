class snapshot::cron::wikidatadumps(
    $user      = undef,
    $group     = undef,
    $filesonly = false,
) {
    file { '/var/log/wikidatadump':
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    file { '/usr/local/etc/dcat_wikidata_config.json':
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/wikibase/dcat_wikidata_config.json',
    }

    class { '::snapshot::cron::wikidatadumps::json':
        user      => $user,
        filesonly => $filesonly,
    }
    class { '::snapshot::cron::wikidatadumps::rdf':
        user      => $user,
        filesonly => $filesonly,
    }
}
