class latexml( $server_name = 'localhost', 
    $latexml_dir = '/usr/local/src/latexml',
    $vhost_name = '*',
    $port = '80'
     ) {

    package { ['texlive',
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
        'libfile-which-perl',
        ]: ensure => present,
    }

    git::clone { 'operations/debs/latexml':
        directory => $latexml_dir,
        origin => 'https://gerrit.wikimedia.org/r/operations/debs/latexml',
        branch => 'production',
    }

    class {'apache':  }

    class {'apache::mod::perl': }

    apache::vhost { 'latexml':
        vhost_name      => $vhost,
        priority        => '10',
        port            => $port,
        docroot         => $latexml_dir,
        template       => '/etc/puppet/modules/latexml/templates/latexml-apache-site.erb',
    }

}
