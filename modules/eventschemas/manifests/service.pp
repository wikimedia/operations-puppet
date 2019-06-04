# Class: eventschemas::service
#
# Sets up an nginx site serving a JSON autoindex of files in
# /srv/schemas/repositories. This also uses a static dist of
# https://github.com/spring-raining/pretty-autoindex
# to allow for nice browsing of the served schemas.
# In this way, schemas can be explored and requested from the service
# programtically via the JSON autoindex, or alternatively
# browsed in HTML in browser via pretty-autoindex.
#
# E.g:
#
# curl http://schema.wikimedia.org:8061/repositories/mediawiki/
# [
#   { "name":"avro", "type":"directory", "mtime":"Wed, 17 Apr 2019 20:04:48 GMT" },
#   { "name":"config", "type":"directory", "mtime":"Wed, 17 Apr 2019 20:04:48 GMT" },
#   { "name":"jsonschema", "type":"directory", "mtime":"Wed, 17 Apr 2019 20:04:48 GMT" },
#   ...
# ]
#
# Or point a browser at http://schema.wikimedia.org to get a pretty-autoindex of repositories/.
#
# == Parameters
#
# [*server_name*]
#   Default: schema.svc.${::site}.wmnet
#
# [*server_alias*]
#   Default: undef
#
# [*port*]
#   Default: 8190
#
class eventschemas::service(
    String $server_name  = "schema.svc.${::site}.wmnet",
    Optional[String] $server_alias = undef,
    $port = 8190,
) {
    require ::eventschemas

    $document_root = "${::eventschemas::base_path}/site"

    # Ensure that all files in files/site are copied to the document root.
    # These include the pretty-autoindex static files.
    file { $document_root:
        ensure  => 'directory',
        source  => 'puppet:///modules/eventschemas/site',
        recurse => 'remote',
    }

    # Symlink the cloned schema repositories_path into the document root.
    file { "${document_root}/repositories":
        ensure => 'link',
        target => $::eventschemas::repositories_path
    }

    nginx::site { $server_name:
        content => template('eventschemas/site.nginx.erb')
    }
}
