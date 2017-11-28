# == Define: motd::script
#
# Provision a message-of-the-day script.
#
# === Parameters
#
# [*priority*]
#   If you need this script to load before or after other scripts, you
#   can make it do so by manipulating this value. In most cases, the
#   default value of 50 should be fine. Value should be between 0 and 99
#
# [*content*]
#   If defined, will be used as the content of the motd script.
#   Undefined by default. Mutually exclusive with 'source'.
#
# [*source*]
#   Path to motd script. Undefined by default. Mutually exclusive
#   with 'content'.
#
# === Examples
#
#  motd::script { 'mediawiki_vagrant':
#    ensure   => present,
#    content  => "#!/bin/sh\necho 'You are using MediaWiki-Vagrant!'\n",
#    priority => 60,
#  }
#
define motd::script(
    $ensure    = present,
    $priority  = 50,
    $content   = undef,
    $source    = undef,
) {
    include ::motd

    # TODO/puppet4 - make all of these checks parameter type definitions instead
    validate_ensure($ensure)
    validate_numeric($priority, 99, 0)
    if $source == undef and $content == undef  { fail('you must provide either "source" or "content"') }
    if $source != undef and $content != undef  { fail('"source" and "content" are mutually exclusive') }

    $safe_name = regsubst($title, '[\W_]', '-', 'G')
    $script    = sprintf('%02d-%s', $priority, $safe_name)

    file { "/etc/update-motd.d/${script}":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        mode    => '0555',
    }
}
