# Configuration files for php5 running on application servers
#
# **fatal_log_file**
# Where to send PHP fatal traces.
#
# requires mediawiki::packages to be in place
class mediawiki::php(
    $fatal_log_file='udp://10.64.0.21:8420'
) {
    include ::mediawiki::packages

    file { '/etc/php5':
        ensure  => directory,
        source  => 'puppet:///modules/mediawiki/etc-php5',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => remote,
        require => Package['php-apc', 'php-mail', 'php5-cli', 'php5-fss'],
    }

    file { '/etc/php5/conf.d/wmerrors.ini':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['php5-wmerrors'],
        content => template('mediawiki/php/wmerrors.ini.erb'),
    }
}
