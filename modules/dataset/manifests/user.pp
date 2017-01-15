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

    $keys = [
              'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuLqmSdltCJzltgEin2j/72k/g7RroS1SE+Tvfh2JRPs2PhWweOJ+omtVp4x+YFNCGBg5wW2GaUnyZkUY0ARzv59aNLsGg87aCCY3J1oAudQ7b+yjrEaE8QebYDPmGTXRDV2osPbXf5UFTzl/O350vRy4q6UHRH+StflSOKhvundwf9QAs2RXNd+96kRe+r8YRcMBGmaJFX3OD9U+Z+gZID8knTvBceVGibEsnYKhHLXLYvMkQF3RfBuZHSsWZiiiXajlcutrLTo8eoG1nCj/FLK1slEXzgopcXEBiX1/LQAGXjgUVF7WmnKZELVCabqY6Qbk+qcmpaM8dL50P4WNdw== datasets_rsync',
              'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8dqOJdtE9YaGS90S3i782TNT5CjMVl2n39f+oHgsiBrAuUglhWvG2FKGyiQzS3cj1akPDcpFRCBRH4oNeIFydfoR3yTcv/6ixwxSZPNwx8HTNEi/GlrPuK24RnNqRRQZuU7UhOC26VIFlgghk9ioiheOEogSkfd1yYhhVi0csQcqg0bBtl3w92L2gcmkG6Mp07HyFBUqEnL/mWtDIhVHrK3Va6f+T9b3SoQ/S5htf6P3zJ7Af2UQlFTvyViU5VY13aC9d6S5yA7UGp8tXWfAu/HnuruNz5HdrOVsCReLaaMzgnZBsgOIOC/euZvni6bxM3tHBcMEXCYM/2/urLB+F datasets_deploy',
            ]
    ssh::userkey { 'datasets':
        ensure  => present,
        content => join($keys, "\n"),
    }
}
