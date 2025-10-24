# SPDX-License-Identifier: Apache-2.0
# @summary varnish VCL common to all instances
# @param vcl_config VCL config
# @param private_repo bool wether to use the private repository or not.
class varnish::common::vcl (
    Hash[String, Any] $vcl_config = {},
    Boolean $private_repo = true,
) {
    require varnish::common
    require varnish::common::errorpage
    require varnish::common::browsersec

    file { '/etc/varnish/translation-engine.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/translation-engine.inc.vcl.erb'),
    }

    file { '/etc/varnish/analytics.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/analytics.inc.vcl.erb'),
    }

    file { '/etc/varnish/analytics-dp-helper.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/analytics-dp-helper.vcl.erb'),
    }

    file { '/etc/varnish/alternate-domains.inc.vcl':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnish/alternate-domains.inc.vcl.erb'),
    }

    if $private_repo {
        # lint:ignore:puppet_url_without_modules
        file { '/etc/varnish/browser-detection.inc.vcl':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///volatile/private_cdn/CDN/vcl/browser-detection.inc.vcl',
        }
        # lint:endignore
    }

    # Directory with test versions of VCL files to run VTC tests
    file { '/usr/share/varnish/tests':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
