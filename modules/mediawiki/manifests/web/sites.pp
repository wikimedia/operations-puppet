class mediawiki::web::sites (
    Array[Mediawiki::SiteCollection] $siteconfigs,
    String $fcgi_proxy,
    String $domain_suffix = 'org',
) {
    tag 'mediawiki', 'mw-apache-config'

    file { '/etc/apache2/sites-enabled/wikidata-uris.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/wikidata-uris.incl',
        before => Service['apache2'],
    }

    # Define all mediawiki sites used in the site, and the site itself.
    $siteconfigs.each |$siteconfig| {
        $sitename = $siteconfig['name']
        # Generic sites get declared pretty simply:
        # We either compile the template indicated in the data, interpolating with the
        # variables above, or we just source the file it's pointing at.
        if $siteconfig['template'] {
            ::httpd::site { $sitename:
                content  => template($siteconfig['template']),
                priority => $siteconfig['priority']
            }
        } elsif $siteconfig['source'] {
            ::httpd::site { $sitename:
                source   =>  "puppet:///modules/${siteconfig['source']}",
                priority => $siteconfig['priority']
            }
        } else {
            # the individual virtualhosts
            $siteconfig['vhosts'].each |$data| {
                $params = $data['params']
                $label = $data['name']
                $complete = merge($siteconfig['defaults'], $params)
                mediawiki::web::vhost { $label:
                    before => Httpd::Site[$sitename],
                    *      => $complete
                }
            }
            # This file just includes all the vhosts declared above.
            ::httpd::site { $sitename:
                content  => template('mediawiki/apache/sitecollection.conf.erb'),
                priority => $siteconfig['priority'],
            }
        }
    }
}
