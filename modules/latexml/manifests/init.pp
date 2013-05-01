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
        'libplack-perl' ,
        'libjson-xs-perl',
        'libfile-which-perl'
        ]: ensure => present,
    }

    git::clone { 'operations/debs/latexml':
        directory => '/home/LaTeXML',
        origin => 'https://gerrit.wikimedia.org/r/operations/debs/latexml',
        branch => 'production',
    }

    class {'apache':  }

    class {'apache::mod::perl': }

    apache::vhost { 'latexml':
        vhost_name      => '*',
        priority        => '10',
        port            => '80',
        docroot         => '/home/LaTeXML/',
        template       => '/etc/puppet/modules/latexml/templates/latexml-apache-site.erb',
    }

}
