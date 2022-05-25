# SPDX-License-Identifier: Apache-2.0

class wmflib::service::conftool {
    $module_path = get_module_path('wmflib')
    $site_nodes  = loadyaml("${module_path}/../../conftool-data/node/${::site}.yaml")[$::site]
}
