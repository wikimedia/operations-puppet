# SPDX-License-Identifier: Apache-2.0

# Instruct Prometheus to probe DNS on $targets

# $targets is the list of nameservers to probe
# $modules is the list of dns probes modules to use
# $targets_file is the path to write the result to
# $extra_labels is an hash to labels to attach to each target,
define netops::prometheus::dns (
  Array[Stdlib::Fqdn] $targets,
  Array[String] $modules,
  String $targets_file,
  Hash[String, String] $extra_labels = {},
) {
  $targets_list = $targets.map |$t| { "${t}:53" }

  $out = $modules.map |$module| {
    {
      targets => $targets_list,
      labels => {
        module => $module,
      } + $extra_labels
    }
  }

  file { $targets_file:
    content => to_yaml(flatten($out)),
  }
}
