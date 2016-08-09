# === Define puppetmaster::puppetdb::config
#
# Defines one ini file and its contents.
define puppetmaster::puppetdb::config($settings) {
    $ini = {"${title}" => $settings}
    $config_dir = '/etc/puppetdb/conf.d'

    file { "/etc/puppetdb/conf.d/${title}.ini":
        content => ini($ini),
        owner   => 'puppetdb',
        group   => 'root',
        mode    => '0640',
        before  => Base::Service_unit['puppetdb'],
    }

}
