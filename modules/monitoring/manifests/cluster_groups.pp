# === Define monitoring::cluster_groups
#
# Wrapper define used for deriving monitoring::group resources
# from the ganglia_clusters hiera data structure.
#
# This can probably go away once we have the future parser
define monitoring::cluster_groups($description, $id, $sites) {

    $site_names = keys($sites)

    # From the data we get from ganglia_clusters, let's create
    # an hash like
    # appserver_eqiad => {description => 'Application servers eqiad'}
    $cluster_groups = hash(
        split(
            inline_template(
                '<%= @site_names.map{ |s| ["#{@title}_#{s}", {"description" => "#{@description} #{s}"}] }.flatten.join("|||") %>'
            ), '\|\|\|'
        )
    )
    create_resources(monitoring::group, $cluster_groups)
}
