# === Define mediawiki::php_enmod
#
# Enables a php config file in newer ubuntu/debian hosts.

define mediawiki::php_enmod {
    if () {
        $modspath = '/etc/php5/mods-available'
        $enmod = 'php5enmod'
    } else {
        $modspath = '/etc/php/7.0/mods-available'
        $enmod = 'phpenmod'
    }

    exec { "PHP module ${title} enable":
        command     => "/usr/sbin/${enmod} -s ALL ${title}",
        refreshonly => true,
        user        => 'root',
        group       => 'root',
        subscribe   => File["${modspath}/${title}.ini"],
    }
}
