# SPDX-License-Identifier: Apache-2.0
# == Class confd::default_instance
#
# Installs the default confd instance
#
# === Parameters
#
# [*srv_dns*] The domain under which to perform a SRV query to discover the
#             backend cluster. Default: $::domain
#
# [*interval*] Polling interval to etcd. If undefined, a direct watch will be
#              executed (the default)
#
# [*prefix*] A global prefix with respect to which confd will do all of its
#            operations. Default: undef
#
class confd::default_instance(
    Wmflib::Ensure   $ensure   = present,
    Optional[String] $prefix   = undef,
    Stdlib::Fqdn     $srv_dns  = $facts['domain'],
    Integer          $interval = 3,
) {
    confd::instance { 'main':
        running => true,
        scheme  => 'https',
        backend => 'etcd',
        *       => wmflib::resource::dump_params(),
    }
}
