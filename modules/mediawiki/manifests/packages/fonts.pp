# == Class: mediawiki::packages::fonts
#
# Provisions font packages used by MediaWiki.
#
class mediawiki::packages::fonts {
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
        'fonts-nafees',
        'fonts-sil-abyssinica',
        'fonts-sil-ezra',
        'fonts-sil-padauk',
        'fonts-sil-scheherazade',
        'fonts-takao-gothic',
        'fonts-takao-mincho',
        'fonts-thai-tlwg',
        'fonts-tibetan-machine',
        'fonts-unfonts-core',
        'fonts-unfonts-extra',
        'texlive-fonts-recommended',
        'ttf-alee',
        'ttf-ubuntu-font-family',    # Not in Debian. T32288, T103325
        'ttf-wqy-zenhei',
        'xfonts-100dpi',
        'xfonts-75dpi',
        'xfonts-base',
        'xfonts-mplus',
        'xfonts-scalable',
        'fonts-sil-nuosusil',        # T83288
        'culmus',                    # T40946
        'culmus-fancy',              # T40946
        'fonts-lklug-sinhala',       # T57462
        'fonts-vlgothic',            # T66002
        'fonts-dejavu-core',         # T65206
        'fonts-dejavu-extra',        # T65206
        'fonts-lyx',                 # T40299
        'fonts-crosextra-carlito',   # T84842
        'fonts-crosextra-caladea',   # T84842
        'fonts-smc',                 # T33950
        'fonts-hosny-amiri',         # T135347
        'fonts-taml-tscu',           # T117919
        'fonts-noto',                # T184664
    ]:
        ensure => present,
    }

    if os_version('ubuntu >= trusty') {
        require_package('ttf-bengali-fonts', 'ttf-devanagari-fonts', 'ttf-gujarati-fonts', 'ttf-kannada-fonts', 'ttf-oriya-fonts', 'ttf-punjabi-fonts', 'ttf-tamil-fonts', 'ttf-telugu-fonts', 'ttf-kochi-gothic', 'ttf-kochi-mincho', 'fonts-mgopen')
    }

    if os_version('debian >= jessie') {
        require_package('fonts-beng', 'fonts-deva', 'fonts-gujr', 'fonts-knda', 'fonts-mlym', 'fonts-orya', 'fonts-guru', 'fonts-taml', 'fonts-telu', 'fonts-gujr-extra', 'fonts-noto-cjk', 'fonts-sil-lateef', 'fonts-ipafont-gothic', 'fonts-ipafont-mincho')
    }

    # In older releases (up to the version present in trusty), fontconfig-config provided
    # a config file which forced antialiasing. This is no longer present in the versions
    # in jessie and later, so provide it manually since otherwise some fonts look distorted
    # in smaller resolutions: T139543
    if os_version('debian >= jessie') {
        file { '/etc/fonts/conf.d/10-antialias.conf':
            source => 'puppet:///modules/mediawiki/fontconfig-antialias.conf',
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
        }
    }
}
