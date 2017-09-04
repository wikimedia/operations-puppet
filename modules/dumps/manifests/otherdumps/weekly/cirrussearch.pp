class dumps::otherdumps::weekly::cirrussearch(
    $user = undef,
) {
    file { '/var/log/cirrusdump':
        ensure => 'directory',
        mode   => '0644',
        owner  => $user,
    }

    logrotate::conf { 'cirrusdump':
        ensure => present,
        source => 'puppet:///modules/dumps/otherdumps/logrot/logrotate.cirrusdump',
    }

    file { '/usr/local/bin/dumpcirrussearch.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/otherdumps/weeklies/dumpcirrussearch.sh',
    }
}
