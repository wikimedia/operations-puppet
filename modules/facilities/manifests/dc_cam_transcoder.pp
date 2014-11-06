class facilities::dc_cam_transcoder {

    system::role { 'misc::dc-cam-transcoder':
        description => 'Data center camera transcoder',
    }

    group { 'video':
        ensure => present,
        name   => 'video',
        system => true,
    }

    user { 'video':
        home       => '/var/lib/video',
        managehome => true,
        system     => true,
    }

    package { 'vlc-nox':
        ensure => 'latest',
    }
}
