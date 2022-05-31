# SPDX-License-Identifier: Apache-2.0
# === Define puppetmaster::puppetdb::config
#
# Defines one ini file and its contents.
define puppetdb::config($settings) {
    $ini = {"${title}" => $settings}
    $config_dir = '/etc/puppetdb/conf.d'

    file { "/etc/puppetdb/conf.d/${title}.ini":
        content => wmflib::ini($ini),
        owner   => 'puppetdb',
        group   => 'root',
        mode    => '0640',
        before  => Service['puppetdb'],
    }

}
