# SPDX-License-Identifier: Apache-2.0
class profile::toolforge::bastion::toolforge_cli() {

    $cli_config = {
        'build' => {
            'dest_repository' => "${::wmcs_project}-harbor.wmcloud.org",
            'builder_image' => "${::wmcs_project}-harbor.wmcloud.org/toolforge/heroku-builder-classic:22",
          },
    }

    # toolforge cli configuration file
    file {'/etc/toolforge.yaml':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => $cli_config.to_yaml,
    }
}
