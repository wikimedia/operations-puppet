class dataset::user {
    # FIXME: wrong (non-system) uid, wrong gid, wrong (non-system) home dir
    user { 'datasets':
        uid        => 10003,
        home       => '/home/datasets',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    group { 'datasets':
        ensure => present,
        name   => 'datasets',
        system => true,
    }

    ssh::userkey { 'datasets':
        ensure  => present,
        content => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuLqmSdltCJzltgEin2j/72k/g7RroS1SE+Tvfh2JRPs2PhWweOJ+omtVp4x+YFNCGBg5wW2GaUnyZkUY0ARzv59aNLsGg87aCCY3J1oAudQ7b+yjrEaE8QebYDPmGTXRDV2osPbXf5UFTzl/O350vRy4q6UHRH+StflSOKhvundwf9QAs2RXNd+96kRe+r8YRcMBGmaJFX3OD9U+Z+gZID8knTvBceVGibEsnYKhHLXLYvMkQF3RfBuZHSsWZiiiXajlcutrLTo8eoG1nCj/FLK1slEXzgopcXEBiX1/LQAGXjgUVF7WmnKZELVCabqY6Qbk+qcmpaM8dL50P4WNdw== datasets',
    }
}
