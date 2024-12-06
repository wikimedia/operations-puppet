# SPDX-License-Identifier: Apache-2.0
# == Define: prometheus::alert::import
# Imports custom alerting rule checks from PuppetDB.
# Also merges alerts belonging to the same group
# into a single prometheus::rule instantiation.
#
# = Parameters
#
# [*instance*]
#   The Prometheus instance the rule is for.
#
# [*site*]
#   The Prometheus site the rule is for.

define prometheus::alert::import (
  String        $instance = $title,
  Wmflib::Sites $site     = $::site,
) {

  # Importing prometheus::alert::placeholder does not
  # affect the system, as it is a dummy resource.
  # The import is required to gather all alerts configured
  # in Puppet and to organize them into rule groups.
  $imported_rules = wmflib::resource::import(
    'prometheus::alert::placeholder',
    undef,
    { tag => "prometheus::alert::rule::${site}::${instance}" }
  )

  # Build an hash of "group key" => list of group rules
  # "group key" is composed of instance + group name to make it unique
  $group_rules = $imported_rules.values.reduce({}) |$memo, $rule| {
    $group_key = [$rule['instance'], $rule['group']]

    if $group_key in $memo {
      $group_rules = $memo[$group_key] + [ $rule['config'] ]
    } else {
      $group_rules = [ $rule['config'] ]
    }

    $memo + { $group_key => $group_rules }
  }

  # Build the resource parameters for prometheus::rule from $group_rules
  $resources = $group_rules.reduce({}) |$memo, $item| {
    $group_key = $item[0]
    $rules = $item[1]

    $instance = $group_key[0]
    $group = $group_key[1]

    $rule_title = "alerts_puppet_${instance}_${group}.yml"

    $memo + {
      $rule_title => {
        'instance' => $instance,
        'content' => {
          'groups' => [{
            'name' => $group,
            'rules' => $rules,
          }]
        }.wmflib::to_yaml
      }
    }
  }

  # A rule group can be instantiated via the prometheus::rule resource.
  # It's essentially the same, but with more than one rule defined.
  create_resources('prometheus::rule', $resources)
}
