# == Define: auditd::rules
#
# Represents a rules file for auditd. See the audit.rules(7) man page.
#
# === Parameters
#
# [*content*]
#   The content of the file provided as a string. Either this or
#   'source' must be specified.
#
# [*source*]
#   The content of the file provided as a puppet:/// file reference.
#   Either this or 'content' must be specified.
#
# === Examples
#
#  # Watch /etc/shadow for changes
#  auditd::rules { 'shadow':
#    ensure  => present,
#    content => "-w /etc/shadow -p wa\n",
#  }
#
define auditd::rules(
    $ensure   = present,
    $content  = undef,
    $source   = undef,
) {
    include ::auditd

    validate_ensure($ensure)

    $basename = regsubst($title, '[\W_]', '-', 'G')

    file { "/etc/audit/rules.d/${basename}.rules":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        notify  => Service['auditd'],
    }
}
