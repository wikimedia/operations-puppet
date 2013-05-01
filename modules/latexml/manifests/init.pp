class latexml( $srvnm='localhost') {

    package { ['texlive',
        'subversion',
        'libclone-perl',
        'libdata-compare-perl',
        'libio-prompt-perl',
        'perlmagick',
        'libparse-recdescent-perl',
        'libxml-libxml-perl',
        'libxml-libxslt-perl',
        'libarchive-zip-perl',
        'libio-string-perl',
        #'apache2',
        'libapache2-mod-perl2',
        'libplack-perl' ,
        'libjson-xs-perl',
        'libfile-which-perl'
        ]: ensure => present,
    }

    git::clone { 'operations/debs/latexml':
        directory => '/home/LaTeXML',
        origin => 'https://gerrit.wikimedia.org/r/operations/debs/latexml'
    }

}
