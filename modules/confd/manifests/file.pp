# == Define confd::file
#
# Defines a service template to be monitored by confd,
# and the corresponding geneated config file.
define confd::file (
    $watch_keys,
    $ensure  = present,
    $uid     = undef,
    $gid     = undef,
    $mode    = '0444',
    $reload  = undef,
    $check   = undef,
    $source  = undef,
    $content = undef,
) {
    $safe_name = regsubst($title, '\/', '_')

    unless ($source or $content) {
        fail('We either need a source file or a content for the config file')
    }
    #TODO validate at least uid and guid

    file { "/etc/confd/conf.d/${safe_name}.toml":
        ensure  => $ensure,
        content => template('confd/service_template.toml.erb'),
    }

    file { "/etc/confd/templates/${safe_name}.tmpl":
        ensure  => $ensure,
        mode    => '0400',
        source  => $source,
        content => $content,
        notify  => Service['confd'],
    }
}
