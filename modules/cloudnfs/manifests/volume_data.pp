# SPDX-License-Identifier: Apache-2.0
class cloudnfs::volume_data () {
    $module_path = get_module_path($module_name)
    $projects = loadyaml("${module_path}/data/projects.yaml")
}
