class mediawiki::web::yaml_defs(
    Stdlib::Unixpath $path,
    Array[Mediawiki::SiteCollection] $siteconfigs,
    String $domain_suffix,
    String $fcgi_proxy,
) {
    $all_defs = $siteconfigs.map |$siteconfig| {
        # the eventual disk path is used as a key, so that
        # the resulting data structure fits well as a configmap.
        if 'vhosts' in $siteconfig {
            # If we have a vhost, we have everything in the yaml.
            # just copy it over.
            $siteconfig
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

    file { $path:
        ensure  => present,
        content => to_yaml({'mw' => {'sites' => $all_defs}}),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
