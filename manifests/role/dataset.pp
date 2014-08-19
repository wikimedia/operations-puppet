# role classes for dataset servers

class role::dataset::pagecountsraw($enable=true) {
    class { '::dataset::cron::pagecountsraw':
        enable  => $enable,
        user    => 'datasets',
        from    => 'gadolinium.wikimedia.org',
        require =>  User['datasets'],
    }
}

# a dumps primary server has dumps generated on this host; other directories
# of content may or may not be generated here (but should all be eventually)
# mirrors to the public should not be provided from here via rsync
class role::dataset::primary {
    $rsync = {
        'public' => true,
        'peers'  => true,
        'labs'   => true,
    }
    $grabs = {
        'kiwix' => true,
    }
    $uploads = {
        'pagecounts' => true,
    }
    class { 'dataset':
        rsync        => $rsync,
        grabs        => $grabs,
        uploads      => $uploads,
    }
    class { 'role::dataset::pagecountsraw': enable => true }
}

# a dumps secondary server may be a primary source of content for a small
# number of directories (but best is not at all)
# mirrors to the public should be provided from here via rsync
class role::dataset::secondary {
    $rsync = {
        'public' => true,
        'peers'  => true,
    }
    $uploads = {
#        'pagecounts' => true,
    }
    $grabs = {
#        'kiwix' => true,
    }
    class { 'dataset':
        rsync        => $rsync,
        grabs        => $grabs,
        uploads      => $uploads,
    }
    class { 'role::dataset::pagecountsraw': enable => false }
}


class role::dataset::systemusers {

    group { 'datasets':
        ensure => present,
        name   => 'datasets',
        system => true,
    }

    user { 'datasets':
        home       => '/home/datasets',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    ssh_authorized_key {
        'datasets':
            ensure => present,
            user   => 'datasets',
            type   => 'ssh-rsa',
            key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAuLqmSdltCJzltgEin2j/72k/g7RroS1SE+Tvfh2JRPs2PhWweOJ+omtVp4x+YFNCGBg5wW2GaUnyZkUY0ARzv59aNLsGg87aCCY3J1oAudQ7b+yjrEaE8QebYDPmGTXRDV2osPbXf5UFTzl/O350vRy4q6UHRH+StflSOKhvundwf9QAs2RXNd+96kRe+r8YRcMBGmaJFX3OD9U+Z+gZID8knTvBceVGibEsnYKhHLXLYvMkQF3RfBuZHSsWZiiiXajlcutrLTo8eoG1nCj/FLK1slEXzgopcXEBiX1/LQAGXjgUVF7WmnKZELVCabqY6Qbk+qcmpaM8dL50P4WNdw==',
    }
}
