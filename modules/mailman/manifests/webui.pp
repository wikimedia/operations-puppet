class mailman::webui {

    httpd::mod_conf { [
        'ssl',
        'headers',
        'rewrite',
        'alias',
        'setenvif',
        'auth_digest',
    ]: }

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
}
