# == Define: mediawiki::web::site
#
# Manages apache virtualhosts for mediawiki-specific configs.
# This is a tiny wrapper around apache::site, of which it exposes most
# parameters. It expects to be passed a template, and by default it
# will precompute two variables:
# - $hhvm_mw_proxy is a full configuration of the proxying for the
# main URLs of the site. It should be included in any virtualhost
# template for a mediawiki instance
# - $hhvm_catchall is a catchall stanza that will ensure any .php or
# .hh file will be routed to HHVM, and should be included in any
# virtualhost used by a HAT server.
#
define mediawiki::web::site (
    $ensure         = present,
    $docroot        = '/var/www',
    $hhvm_host_port = '127.0.0.1:9000',
    $priority       = undef,
    $content        = undef,
    ) {

    $hhvm_mw_proxy = template('mediawiki/apache/hhvm_mw_proxy.erb')
    $hhvm_catchall = template('mediawiki/apache/hhvm_catchall.erb')

    apache::site { "$title":
        ensure   => $ensure,
        priority => $priority,
        content  => $content,
    }
}
