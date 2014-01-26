# imagescaler.pp

# Virtual resource for the monitoring server
@monitor_group { 'imagescaler': description => 'image scalers' }

# need to move the /a/magick-tmp stuff to /tmp/magick-tmp
#this will require a mediawiki change, it would seem

class imagescaler::cron {
    cron { 'removetmpfiles':
        ensure  => 'present',
        command => "for dir in /tmp /a/magick-tmp /tmp/magick-tmp; do find \$dir -ignore_readdir_race -type f \\( -name 'gs_*' -o -name 'magick-*' -o -name 'localcopy_*svg' -o -name 'vips-*.v' \\) -cmin +15 -exec rm -f {} \\;; done",
        user    => 'root',
        minute  => '*/5',
    }
}

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
        ensure => 'latest',
    }

}

class imagescaler::packages::fonts {
    package {
        [
            'culmus', # bug 38946
            'culmus-fancy', # bug 38946

            'fonts-arabeyes',
            'fonts-lklug-sinhala', # bug 55462
            'fonts-arphic-ukai',
            'fonts-arphic-uming',
            'fonts-farsiweb',
            'fonts-kacst',
            'fonts-khmeros',
            'fonts-lao',
            'fonts-liberation',
            'fonts-linuxlibertine',
            'fonts-manchufont',
            'fonts-mgopen',
            'fonts-nafees',
            'fonts-sil-abyssinica',
            'fonts-sil-ezra',
            'fonts-sil-padauk',
            'fonts-sil-scheherazade',
            'fonts-sil-nuosusil',  # used to be fonts-sil-yi RT 6500
            'fonts-takao-gothic',
            'fonts-takao-mincho',
            'fonts-thai-tlwg',
            'fonts-tibetan-machine',
            'fonts-unfonts-extra',

            'gsfonts',
            'texlive-fonts-recommended',

            'ttf-alee',
            'ttf-bengali-fonts',
            'ttf-devanagari-fonts',
            'ttf-gujarati-fonts',
            'ttf-kannada-fonts',
            'ttf-lyx', # 'Computer Modern' - bug 38299
            'ttf-malayalam-fonts',
            'ttf-oriya-fonts',
            'ttf-punjabi-fonts',
            'ttf-tamil-fonts',
            'ttf-telugu-fonts',
            'ttf-ubuntu-font-family',
            'ttf-wqy-zenhei',

            'xfonts-100dpi',
            'xfonts-75dpi',
            'xfonts-base',
            'xfonts-mplus',
            'xfonts-scalable'
        ]:
        ensure => latest,
    }
}


class imagescaler::files {

    file { '/etc/wikimedia-image-scaler':
        content => 'The presence of this file alters the apache configuration, to be suitable for image scaling.',
        #notify => Service[apache],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file { '/etc/fonts/conf.d/70-yes-bitmaps.conf':
        ensure => 'absent',
    }

    file { '/etc/fonts/conf.d/70-no-bitmaps.conf':
        ensure => 'link',
        target => '/etc/fonts/conf.avail/70-no-bitmaps.conf',
    }

    file { '/a':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/a/magick-tmp':
        ensure  => 'directory',
        owner   => 'apache',
        group   => 'root',
        mode    => '0755',
        require => File['/a'],
    }

    file { '/tmp/magick-tmp':
        ensure => 'directory',
        owner  => 'apache',
        group  => 'root',
        mode   => '0755',
    }

}
