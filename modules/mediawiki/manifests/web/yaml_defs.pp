class mediawiki::web::yaml_defs(
    Stdlib::Unixpath $path,
    Array[Mediawiki::SiteCollection] $siteconfigs,
    String $domain_suffix,
    String $fcgi_proxy,
    String $statsd,
) {
    $all_defs = $siteconfigs.map |$siteconfig| {
        # the eventual disk path is used as a key, so that
        # the resulting data structure fits well as a configmap.
        if 'vhosts' in $siteconfig {
            # If we have a vhost, we have everything in the yaml.
            # We need to untangle the vhosts structures first
            $vhosts =  $siteconfig['vhosts'].map |$vhost| {
                $k8s_params = pick($vhost['k8s_only_params'], {})
                $vhost['params'].merge({'name' => $vhost['name']}).merge($k8s_params)
            }
            # Now copy over the siteconfig, not before patching the vhosts.
            $siteconfig.merge({'vhosts' => $vhosts})
        } elsif $siteconfig['source'] {
            # Get the contents of the source file
            $source_url = "puppet:///modules/${siteconfig['source']}"
            $sc = {
                'name' => $siteconfig['name'],
                'priority' => $siteconfig['priority'],
                'content' => inline_template('<%= Puppet::FileServing::Content.indirection.find(@source_url).content.force_encoding("utf-8").gsub(/\*:80/, "*:${APACHE_RUN_PORT}") %>')
            }
            $sc
        } elsif $siteconfig['template'] {
            {
                'name' => $siteconfig['name'],
                'priority' => $siteconfig['priority'],
                'content' => regsubst(template($siteconfig['template']), '\*:80', "*:\${APACHE_RUN_PORT}", 'G')
            }
        }
    }
    # php error handling for wmerrors is in puppet. Let's pass it to k8s as well.
    $statsd_parts = split($statsd, ':')
    $statsd_host = $statsd_parts[0]
    $statsd_port = $statsd_parts[1]
    $wmerrors_config = {
        'error-params.php' => template('profile/mediawiki/error-params.php.erb'),
        'fatal-error.php' => inline_template('<%= Puppet::FileServing::Content.indirection.find("puppet:///modules/profile/mediawiki/php/php7-fatal-error.php").content.force_encoding("utf-8") %>')
    }

    file { $path:
        ensure  => present,
        content => to_yaml({'mw' => {'sites' => $all_defs, 'wmerrors' => $wmerrors_config}}),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
