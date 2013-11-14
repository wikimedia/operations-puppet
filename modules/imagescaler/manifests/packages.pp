#Class for manageing imagescalers packages
class imagescaler::packages {

    include imagescaler::packages::fonts

    package {
        [
            'imagemagick',
            'ghostscript',
            'ffmpeg',
            'ffmpeg2theora',
            'librsvg2-bin',
            'djvulibre-bin',
            'netpbm',
            'libogg0',
            'libvorbisenc2',
            'libtheora0',
            'oggvideotools',
            'libvips15',
            'libvips-tools',
            'libjpeg-turbo-progs'
        ]:
        ensure => latest
    }
}

