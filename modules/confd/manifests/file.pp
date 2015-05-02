# == Define confd::file
#
# Defines a service template to be monitored by confd,
# and the corresponding geneated config file.
define confd::file (
    $watch_keys,
    $dest    = undef,
    $uid     = undef,
    $gid     = undef,
    $mode    = '0444',
    $reload  = undef,
    $check   = undef,
    $source  = undef,
    $content = undef
    ) {
    if $dest == undef {
        $dest = $title
    }
    unless ($source or $content) {
        fail('We either need a source file or a content for the config file')
    }
    #TODO validate at least uid and guid

    file { '/etc/confd/conf.d/${name}.toml':
        ensure  => $ensure,
        content => template('confd/service_template.toml.erb'),
    }

    file { '/etc/confd/templates/$name.tmpl':
        ensure  => $ensure,
        mode    => $mode,
        source  => $source,
        content => $content,
        notify  => Service['confd'],
    }
}
