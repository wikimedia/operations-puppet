# SPDX-License-Identifier: Apache-2.0
# == Class: profile::grafana::plugin::grafana_image_renderer
#

class profile::grafana::plugin::grafana_image_renderer() {

    class { '::grafana::plugin::grafana_image_renderer': }

}
