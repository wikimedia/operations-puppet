# Sets up a web server to be used by mailman.
class mailman::webui {

    $lists_servername = hiera('mailman::lists_servername')

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    httpd::site { 'lists.wikimedia.org':
        content => template('mailman/lists.wikimedia.org.erb'),
    }

    # htdigest file for private list archives
    file { '/etc/apache2/arbcom-l.htdigest':
        content   => secret('mailman/arbcom-l.htdigest'),
        owner     => 'root',
        group     => 'www-data',
        mode      => '0440',
        require   => Class['httpd'],
        show_diff => false,
    }

    # Add files in /var/www (docroot)
    file { '/var/www':
        source  => 'puppet:///modules/mailman/docroot/',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => 'remote',
    }

    # Add a new default theme to make mailman prettier
    file { '/var/lib/mailman/templates':
        ensure => link,
        target => '/etc/mailman',
    }

    # Add default theme to make mailman prettier.
    #  Recurse => remote adds a bunch of files here and there
    #  while leaving the by-hand mailman config files in place.
    file { '/etc/mailman':
        source  => 'puppet:///modules/mailman/templates/',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => 'remote',
    }

    # Not using require_package so apt::pin may be applied
    # before attempting to install package.
    package { 'libapache2-mod-security2':
        ensure => present,
    }

    # Ensure that the CRS modsecurity ruleset is not used. it has not
    # yet been tested for compatibility with our mailman instance and may
    # cause breakage.
    file { '/etc/apache2/mods-available/security2.conf':
        ensure  => present,
        source  => 'puppet:///modules/mailman/modsecurity/security2.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['libapache2-mod-security2'],
    }

}
