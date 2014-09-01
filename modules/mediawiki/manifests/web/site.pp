# == Define: mediawiki::site
#
# Manages apache virtualhosts for mediawiki-specific configs.
# This is a tiny wrapper around apache::site, of which it exposes most
# parameters. It expects to be passed a template, and by default it
# will precompute a variable $engine_include that can be used in the
# template to include code that will allow to redirect traffic to HHVM
# or to the traditional zend mod_php depending on the presence of one
# variable.
#
define mediawiki::site (
    $ensure         = present,
    $doc_root       = '/var/www',
    $hhvm_host_port = '127.0.0.1:9000',
    $priority       = 50,
    $content        = undef,
    $replaces       = undef,
    $hhvm_rewrite   = 'full',
    ) {

    $engine_include = $hhvm_rewrite ? {
        'full'    => template('mediawiki/apache/hhvm_full.erb'),
        'minimal' => template('mediawiki/apache/hhvm_minimal.erb')
        default   => fail('hhvm_rewrite must be either "full" or "minimal"')
    }

    apache::site { "$title":
        ensure   => $ensure,
        priority => $priority,
        content  => $content,
        replaces => $replaces
    }
}
