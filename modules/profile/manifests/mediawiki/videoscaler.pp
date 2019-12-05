class profile::mediawiki::videoscaler()
{
    include ::mediawiki::users

    # Backport of libvpx 1.7 and row-mt support, can be removed once
    # video scalers are migrated to Debian buster
    apt::repository { 'ffmpeg-vp9':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => 'stretch-wikimedia',
        components => 'component/vp9',
        notify     => Exec['apt_update_ffmpeg'],
    }

    # ffmpeg has a dependency on the base version of the release, so e.g. (>= 7:3.2.14)
    # This isn't sufficient it make apt pull in our patched version, so explicitly add
    # pinning for the various ffmpeg libraries as well

    $ffmpeg_packages = ['ffmpeg', 'libavcodec57', 'libavdevice57', 'libavfilter6', 'libavformat57',
                        'libavresample3', 'libpostproc54', 'libswresample2', 'libavutil55', 'libswscale4']

    apt::pin { 'ffmpeg-vp9-stretch':
        pin      => 'release c=component/vp9',
        priority => '1001',
        before   => Package[$ffmpeg_packages],
    }

    package { $ffmpeg_packages:
        ensure  => present,
        require => [ Apt::Repository['ffmpeg-vp9'], Exec['apt_update_ffmpeg']],
    }

    # Needed to make sure the revised ffmpeg gets installed on fresh installs
    exec {'apt_update_ffmpeg':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }
}
