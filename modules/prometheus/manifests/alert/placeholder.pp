# SPDX-License-Identifier: Apache-2.0
# == Define: prometheus::alert::placeholder
# prometheus::alert::placeholder is used to
# collect all alert rules configured in Puppet
# using prometheus::alert::rule, through an
# export/import mechanism. It is a dummy resource,
# as it doesn't perform any actual action.
#
# = Parameters
#
# [*instance*]
#   The Prometheus instance the rule is for.
#
# [*group*]
#   The Prometheus rule group where the alerting rule should be included.
#
# [*config*]
#   The alert configuration.

define prometheus::alert::placeholder (
    String                   $instance,
    Prometheus::Alert::Group $group,
    Hash                     $config,
) {
}
