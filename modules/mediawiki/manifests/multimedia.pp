# == Class: mediawiki::multimedia
#
# Provisions packages and configurations used by MediaWiki for image
# and video processing.
#
class mediawiki::multimedia {
    include ::mediawiki::multimedia::fonts

    cron { 'clear_imagemagick_temp_files':
        ensure  => present,
        command => strip(template('mediawiki/clear_magick_tmp.erb')),
        user    => 'root',
        minute  => '*/5',
    }

    if ubuntu_version('>= trusty') {
        $libav_package   = 'libav-tools'
        $libvips_package = 'libvips37'
    } else {
        $libav_package   = 'ffmpeg'
        $libvips_package = 'libvips15'
    }

    package { [
        $libav_package,
        $libvips_package,
        'ffmpeg2theora',
        'ghostscript',
        'libjpeg-turbo-progs',
        'libogg0',
        'libtheora0',
        'libvips-tools',
        'libvorbisenc2',
        'netpbm',
        'oggvideotools',
    ]:
        ensure => present,
    }

    file { '/etc/fonts/conf.d/70-no-bitmaps.conf':
        ensure => link,
        target => '/etc/fonts/conf.avail/70-no-bitmaps.conf',
    }

    file { '/a/magick-tmp':
        ensure  => directory,
        owner   => 'apache',
        group   => 'root',
        mode    => '0755',
    }

    file { '/tmp/magick-tmp':
        ensure => directory,
        owner  => 'apache',
        group  => 'root',
        mode   => '0755',
    }
}

class mediawiki::multimedia::fonts {
    package { [
        'fonts-arabeyes',
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
        'fonts-takao-gothic',
        'fonts-takao-mincho',
        'fonts-thai-tlwg',
        'fonts-tibetan-machine',
        'fonts-unfonts-extra',
        'texlive-fonts-recommended',
        'ttf-alee',
        'ttf-bengali-fonts',
        'ttf-devanagari-fonts',
        'ttf-gujarati-fonts',
        'ttf-kannada-fonts',
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
        'xfonts-scalable',
        'fonts-sil-nuosusil',        # RT 6500
        'culmus',                    # Bug 38946
        'culmus-fancy',              # Bug 38946
        'fonts-lklug-sinhala',       # Bug 55462
        'fonts-vlgothic',            # Bug 64002
        'ttf-dejavu-core',           # Bug 63206
        'ttf-dejavu-extra',          # Bug 63206
        'ttf-kochi-gothic',          # Bug 64002
        'ttf-kochi-mincho',          # Bug 64002
        'ttf-lyx',                   # Bug 38299
    ]:
        ensure => present,
    }
}
