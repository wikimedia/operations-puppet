# = Class: elasticsearch::plugin
#
# Manages an elasticsearch plugin installation.  This is known to work with site
# plugins but might not properly handle The title should start with
# elasticsearch.  The contents of
# puppet:///modules/elasticsearch/plugins/$title-without-elasticsearch/ will be
# installed to the elasticsearch plugin repository.
#
# == Sample usage:
#
#   elasticsearch::plugin { "elasticsearch-paramedic": }
#
define elasticsearch::plugin() {
    if $title =~ /^elasticsearch-(.*)$/ {
        $plugin_name = $1
    } else {
        fail('$title must start with elasticsearch-')
    }
    file { "/usr/share/elasticsearch/plugins/$plugin_name":
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/elasticsearch/plugins/$plugin_name",
    }
}
