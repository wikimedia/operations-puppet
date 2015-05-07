# role classes for dataset servers

class role::dataset::pagecountsraw($enable = true) {
    class { '::dataset::cron::pagecountsraw':
        enable  => $enable,
        user    => 'datasets',
        source  => 'stat1002.eqiad.wmnet::hdfs-archive/pagecounts-raw/*/*/',
        require =>  User['datasets'],
    }
}

# == Class role::dataset::pagecounts_all_sites
#
# NOTE: this requires that an rsync server
# module named 'hdfs-archive' is configured on stat1002.
#
# This will make these files available at
# http://dumps.wikimedia.org/other/pagecounts-all-sites/
#
class role::dataset::pagecounts_all_sites($enable = true) {
    class { '::dataset::cron::pagecounts_all_sites':
        source =>  'stat1002.eqiad.wmnet::hdfs-archive/pagecounts-all-sites',
        enable => $enable,
        user   => 'datasets',
    }
}

# == Class role::dataset::mediacounts
#
# NOTE: this requires that an rsync server
# module named 'hdfs-archive' is configured on stat1002.
#
# This will make these files available at
# http://dumps.wikimedia.org/other/mediacounts/
#
class role::dataset::mediacounts($enable = true) {
    class { '::dataset::cron::mediacounts':
        source =>  'stat1002.eqiad.wmnet::hdfs-archive/mediacounts',
        enable => $enable,
        user   => 'datasets',
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
        rsync   => $rsync,
        grabs   => $grabs,
        uploads => $uploads,
    }
    class { 'role::dataset::pagecountsraw': enable => true }

    class { 'role::dataset::pagecounts_all_sites':
        enable => true,
    }

    class { 'role::dataset::mediacounts':
        enable => true,
    }
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
        rsync   => $rsync,
        grabs   => $grabs,
        uploads => $uploads,
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

class role::dataset::publicdirs {

    file { '/a/public-datasets':
        ensure => 'directory',
        owner  => 'root',
        group  => 'deployment',
        mode   => '0775',
    }

}
