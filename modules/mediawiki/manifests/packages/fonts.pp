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
        'fonts-unfonts-core',
        'fonts-unfonts-extra',
        'texlive-fonts-recommended',
        'fonts-alee',
        'fonts-beng',
        'fonts-deva',
        'fonts-gujr',
        'fonts-knda',
        'fonts-mlym',
        'fonts-orya',
        'fonts-guru',
        'fonts-taml',
        'fonts-telu',
        'fonts-wqy-zenhei',
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
        'ttf-kochi-gothic',          # T66002
        'fonts-vlgothic',
        'fonts-ipafont--mincho',     # T66002
        'fonts-lyx',                 # T40299
    ]:
        ensure => present,
    }
    # T84842
    if os_version('ubuntu >= trusty || debian >= jessie') {
        package { ['fonts-crosextra-carlito', 'fonts-crosextra-caladea']:
            ensure => present,
        }
    }
}
