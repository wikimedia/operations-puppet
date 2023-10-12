# SPDX-License-Identifier: Apache-2.0
# == security::access::config ==
#
# Allows defining an access.conf stanza to limit logins into the server to
# specified sets of groups or users.  See access.conf(5) for syntax.
#
# Having a security::access::config resource in the manifest implicitly
# pulls in the security::access class that creates the access.conf.d
# directory and adds access.conf checking to the system PAM configuration.
#
# === Parameters ===
#
# [*content*]
#   The content of the access.conf fragment.  Either this or [*source*]
#   must be specified.
#
# [*source*]
#   The source of the access.conf fragment.  Either this or [*content*]
#   must be specified.
#
# [*priority*]
#   The priority at which the fragment will be concatenated with any
#   other specified ones, with lower priorities coming first in the
#   resulting access.conf file.  Note that access.conf is evaluated in
#   order, with the first matching entry being used.
#
# === Example ===
#
# This resource limits logging into the server only to the "ops" group
# and the root user:
#
# security::access::config { 'ospen-only':
#    content => "- : ALL EXCEPT (ops) root : ALL\n",
# }

define security::access::config(
    Wmflib::Ensure               $ensure   = 'present',
    Optional[String]             $content  = undef,
    Optional[Stdlib::Filesource] $source   = undef,
    Integer[0,99]                $priority = 50,
) {
    include security::access

    concat::fragment { "security-access-${title}":
        target  => '/etc/security/access.conf',
        source  => $source,
        content => $content,
        order   => $priority,
    }
}
