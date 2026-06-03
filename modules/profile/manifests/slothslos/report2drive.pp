# SPDX-License-Identifier: Apache-2.0
# == Class: profile::slothslos::report2drive
#
# @summary
# Manage the top-level `slothslos::report2drive` class with simple
# parameter forwarding.
#
# Manage multiple report2drive instances from a configuration hash.
#
# @description
# This wrapper class provides a location to set the
# `user` and optional `ensure` parameters for the `slothslos::report2drive`
# defined class.
#
# This class iterates over a hash of instance configurations and declares a
# `slothslos::report2drive::instance` resource for each entry.
#
# @param ensure [Wmflib::Ensure, Optional] Desired resource state for the
#   `slothslos::report2drive` class. Defaults to `present`.
# @param user [String] The username the `report2drive` service runs as.
#   Default is looked up from `profile::slothslos::report2drive::user` and
#   falls back to `'report2drive'` when not supplied.
# @param active_host [Stdlib::Fqdn] FQDN of the active Grafana host. Default
#   value is looked up from `profile::grafana::active_host`.
# @param configs [Profile::Slothslos::Report2drive::Instances] A hash of
#   instance configurations (typically produced by a deep merge so that
#   secrets can come from a private data source).
#
class profile::slothslos::report2drive (
    Wmflib::Ensure                              $ensure      = lookup('profile::slothslos::report2drive::enabled', {'default_value' => 'present' }),
    String                                      $user        = lookup('profile::slothslos::report2drive::user', { 'default_value' => 'report2drive' }),
    Stdlib::Fqdn                                $active_host = lookup('profile::grafana::active_host'),
    # The $configs variable is the result of a deep merge,
    # since secrets such as the Grafana bearer token and
    # the Google key come from private.git.
    Profile::Slothslos::Report2drive::Instances $instances   = lookup('profile::slothslos::report2drive::instances'),
) {
    class { 'slothslos::report2drive':
        ensure => $ensure,
        user   => $user,
    }

    $instances.each |$name, $params| {
        # drive_key must be converted from Hash[String, String] to JSON.
        # The enabled parameter is used in conjunction with active_host
        # to determine whether the report should be generated (and where).
        # The enabled parameter needs to be removed from the dict
        # since it's not a parameter of the class.
        slothslos::report2drive::instance { $name:
            * => delete(
                ($params + {
                    'drive_key' => $params['drive_key'].to_json_pretty(),
                    'ensure'    => (($ensure == 'present') and ($active_host == $facts['networking']['fqdn']) and $params['enabled']) ? {
                        true  => present,
                        false => absent,
                    },
                    'user'      => $user,
                }),
                'enabled'
            ),
        }
    }
}
