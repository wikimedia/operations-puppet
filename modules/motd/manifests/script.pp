# == Define: motd::script
#
# Provision a message-of-the-day script.
#
# === Parameters
#
# [*priority*]
#   If you need this script to load before or after other scripts, you
#   can make it do so by manipulating this value. In most cases, the
#   default value of 50 should be fine.
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

    validate_ensure($ensure)
    if !is_integer($priority) or $priority < 10 or $priority > 99 {
        fail("motd::script: caller: ${caller_module_name} passed incorrect priority (must be 10 - 99)")
    }
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
