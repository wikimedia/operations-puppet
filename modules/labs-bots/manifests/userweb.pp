class labs-bots::userweb {
    # Common stuff
    include labs-bots::common

    # Vhost stuff
    define vhost($server_name=$title, $document_root, $alias=[], $ensure="present") {
        file {
            "/etc/apache2/sites-enabled/$server_name":
                require => [ Package[libapache2-mod-php5] ],
                content => template('labs-bots/vhost.erb'),
                mode => 0440,
                owner => root,
                group => www-data,
                ensure => $ensure,
                notify => Service[ apache2 ];
        }
    }

    # Vhosts
    vhost {
        'bots.wmflabs.org':
            document_root => '/var/www/';

        'report.cluebot.org':
            document_root => '/data/project/public_html/damian/',
            alias => ['report.cbng.cluenet.org', 'report.cluebot.cluenet.org'];
    }


    # Package deps
    package {
        [
        'apache2', 'libapache2-mod-php5', 'php5', 'php5-cli',
        'php5-mysql',
        
        # DR Trigon Bots
        'python-matplotlib', 'python-numpy', 'python-BeautifulSoup',
        'python-lxml',
        ]:
        ensure => latest;
    }

    # Apache service
    service {
        apache2:
            require => [ Package[apache2] ],
            subscribe => [ Package[libapache2-mod-php5],
                            File["/etc/apache2/mods-enabled/userdir.conf"],
                            File["/etc/apache2/mods-enabled/userdir.load"],
                            File["/etc/apache2/conf.d/namevirtualhost"],
                            File["/etc/apache2/sites-enabled/000_default"], ],
            ensure => running;
    }

    file {
        # User data
        '/data/project/public_html':
            ensure => directory;

        # Userdir config
        '/etc/apache2/mods-enabled/userdir.conf':
            source => 'puppet:///modules/labs-bots/userweb/userdir.conf';

        '/etc/apache2/mods-enabled/userdir.load':
            ensure => link,
            target => '../mods-available/userdir.load';

        # bots.wmflabs.org site content
        '/var/www/index.html':
            ensure => present,
            source => 'puppet:///modules/labs-bots/userweb/bots.wmflabs.org/index.html';

        '/var/www/robots.txt':
            ensure => present,
            source => 'puppet:///modules/labs-bots/userweb/bots.wmflabs.org/robots.txt';

        # Update script
        '/usr/local/bin/update_userdirs.py':
            ensure => present,
            source => 'puppet:///modules/labs-bots/userweb/update.py';

        # Name virtual host
        '/etc/apache2/conf.d/namevirtualhost':
            content => 'NameVirtualHost *:80',
            mode => 0440,
            owner => root,
            group => www-data;

        # vhosts
        '/etc/apache2/sites-enabled/000_default':
            ensure => absent;
    }

    # Update cronjob
    cron {
        'update-userdir':
            command => '/usr/bin/python /usr/local/bin/update_userdirs.py &> /dev/null',
            user => root,
            minute => '*/5',
            ensure => present,
            require => File[ '/usr/local/bin/update_userdirs.py']
    }
}
