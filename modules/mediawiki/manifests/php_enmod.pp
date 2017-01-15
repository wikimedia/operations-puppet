# === Define mediawiki::php_enmod
#
# Enables a php config file in newer ubuntu/debian hosts.

define mediawiki::php_enmod {
    requires_os('ubuntu >= trusty || debian >= jessie')

    exec { "PHP module ${title} enable":
        command     => "/usr/sbin/php5enmod -s ALL ${title}",
        refreshonly => true,
        user        => 'root',
        group       => 'root',
        subscribe   => File["/etc/php5/mods-available/${title}.ini"],
    }
}
