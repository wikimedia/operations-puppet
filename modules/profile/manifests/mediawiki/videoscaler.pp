class profile::mediawiki::videoscaler()
{
    include ::mediawiki::users

    # Backport of libvpx 1.7 and row-mt support, can be removed once
    # video scalers are migrated to Debian buster
    if os_version('debian == stretch') {

        # ffmpeg has a dependency on the base version of the release, so e.g. (>= 7:3.2.14)
        # This isn't sufficient it make apt pull in our patched version, so explicitly add
        # pinning for the various ffmpeg libraries as well
        $ffmpeg_packages = ['ffmpeg', 'libavcodec57', 'libavdevice57', 'libavfilter6', 'libavformat57',
                            'libavresample3', 'libpostproc54', 'libswresample2', 'libavutil55',
                            'libswscale4']

        apt::package_from_component { 'ffmpeg-vp9':
            component => 'component/vp9',
            packages  => $ffmpeg_packages,
        }
    }
}
