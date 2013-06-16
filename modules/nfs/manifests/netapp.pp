# Classes for NetApp mounts used on multiple servers
class nfs::netapp::common {
    include nfs::common

    $device = $::site ? {
        pmtpa => "nas1-a.pmtpa.wmnet",
        eqiad => "nas1001-a.eqiad.wmnet",
        default => undef,
    }

    $options = "bg,intr"
}

class nfs::netapp::home($ensure="mounted", $mountpoint="/home") {
    include common

    file { $mountpoint: ensure => directory }

    mount { $mountpoint:
        require => File[$mountpoint],
        device => "${nfs::netapp::common::device}:/vol/home_${::site}",
        fstype => nfs,
        options => $nfs::netapp::common::options,
        ensure => $ensure
    }
}

class nfs::netapp::home::othersite($ensure="mounted", $mountpoint=undef) {
    include common

    $peersite = $::site ? {
        'pmtpa' => "eqiad",
        'eqiad' => "pmtpa",
        default => undef
    }
    $path = $mountpoint ? {
        undef => "/srv/home_${peersite}",
        default => $mountpoint
    }

    file { $path: ensure => directory }

    mount { $path:
        require => File[$path],
        device => "${nfs::netapp::common::device}:/vol/home_${peersite}",
        fstype => nfs,
        options => "${nfs::netapp::common::options},ro",
        ensure => $ensure
    }
}

class nfs::netapp::fr_archive(
        $ensure="mounted",
        $mountpoint="/archive/udplogs"
    ) {

    include common

    file { $mountpoint: ensure => directory }

    mount { $mountpoint:
        require => File[$mountpoint],
        device => "${nfs::netapp::common::device}:/vol/fr_archive",
        fstype => nfs,
        options => $nfs::netapp::common::options,
        ensure => $ensure
    }
}
