# SPDX-License-Identifier: Apache-2.0
# lint:ignore:only_variable_string

define profile::pyrra::filesystem::slo(
    $spec,
    String $team,
    String $service,
    Optional[Integer] $revision = undef,
    Optional[String] $site = undef,
    String $sloname  = $title,
    Wmflib::Ensure $ensure = present,
) {

    $slo_name = $revision ? {
        undef   => $sloname,
        default => "${sloname}-v${revision}",
    }

    $labels = delete_undef_values({
      'pyrra.dev/team'     => $team,
      'pyrra.dev/service'  => $service,
      'pyrra.dev/revision' => $revision,
      'pyrra.dev/site'     => $site,
    })

    pyrra::filesystem::config { "${title}.yaml":
      ensure  => $ensure,
      content => to_yaml({
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind'       => 'ServiceLevelObjective',
        'metadata'   => { 'name' => $slo_name, 'labels' => $labels },
        'spec'       => $spec,
      }),
    }

}

# lint:endignore
