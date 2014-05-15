# application server required packages
class applicationserver::packages {

    package { [ 'libapache2-mod-php5', 'php5-common', 'php5-cli', 'libmemcached11' ]:
        ensure => latest,
    }

    # Standard PHP extensions
    package { [
        'php5-curl',
        'php5-intl',
        'php5-memcached',
        'php5-mysql',
        'php5-redis',
        'php5-xmlrpc',
    ]:
        ensure => latest,
    }

    # Wikimedia-specific PHP extensions
    package { [
        'php-luasandbox',
        'php-wikidiff2',
        'php5-wmerrors',
        'php5-fss',
    ]:
        ensure => latest,
    }

    # Pear modules
    package { [
        'php-mail',
        'php-mail-mime',
    ]:
        ensure => latest,
    }
}
