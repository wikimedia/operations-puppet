# SPDX-License-Identifier: Apache-2.0
# == Class: profile::grafana::plugin::grafana_image_renderer
#

class profile::grafana::plugin::grafana_image_renderer(
    Pattern[/\A[0-9a-fA-F]{32}\z/] $image_renderer_token    = lookup('profile::grafana::plugin::grafana_image_renderer::renderer_token'),
) {

    class { '::grafana::plugin::grafana_image_renderer':
        image_renderer_token => $image_renderer_token,
    }

}
