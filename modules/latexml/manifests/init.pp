class latexml( $srvnm='localhost') {

    package { ['texlive', 'subversion', 'libclone-perl', 'libdata-compare-perl',
    'libio-prompt-perl', 'perlmagick', 'libparse-recdescent-perl',
    'libxml-libxml-perl', 'libxml-libxslt-perl', 'libarchive-zip-perl', 'unzip',
    'apache2', 'libapache2-mod-perl2', 'libplack-perl',  'libio-string-perl',
    'libfile-which-perl', 'libjson-xs-perl', 'make']:
    ensure  => present,
    }

    file { '/home/LaTeXML':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '7777'
    }

    exec{ 'checkout-LaTeXML':
    command => '/usr/bin/svn co -r 3364 \
        https://svn.mathweb.org/repos/LaTeXML/branches/arXMLiv /home/LaTeXML/',
    require => Package['subversion'],
    }

    exec { 'get-Mojolicious':
    command => '/bin/sh -c "curl -L cpanmin.us | perl - Mojolicious"',
    cwd=> '/home/LaTeXML'
    }

    exec { 'Perl-make':
    command => '/usr/bin/perl Makefile.PL',
    cwd=> '/home/LaTeXML'
    }

    exec { '/usr/bin/make':
    cwd=> '/home/LaTeXML'
    }

    exec { 'install-LaTeXML':
    command => '/usr/bin/make install',
    cwd=> '/home/LaTeXML',
    user => root,
    }

    service { 'apache2':
    ensure  => 'running',
    enable  => 'true',
    require => Package['apache2'],
    }

    file { 'apache-latexml-site':
    path    => '/etc/apache2/sites-available/latexml',
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('/etc/puppet/modules/latexml/templates/latexml-apache-site.erb'),
    notify  => Service['apache2'],
    }

    exec { 'enable-latexml':
    command => '/usr/sbin/a2ensite latexml',
    cwd=> '/etc/apache2/sites-available/',
    user => root,
    }

}
