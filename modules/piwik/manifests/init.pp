# == Class: piwik
#
# Piwik is an open-source analytics platform.
# FIXME: document
#
class piwik( $settings ) {
    require_package('piwik')

    file { '/etc/piwik/config.ini.php':
        content => php_ini($settings),
        owner   => 'root',
        group   => 'www-data',
        mode    => '0444',
        require => Package['piwik'],
    }
}
