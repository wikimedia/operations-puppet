# == Function: kafka_cluster_name(string prefix[, string site])
#
# Determines the Kafka cluster name based on the supplied prefix.
# NOTE: this function is WMF-specific and takes into account the fact that the
# analytics cluster's name in production has historically been 'eqiad'
#
# === Parameters
#
# [*prefix*]
#   The cluster prefix to get the name for (currently only 'main' and
#   'analytics' are the only possible values). Required.
#
# [*site*]
#   The site for which to get the cluster name ('eqiad', 'codfw'). Default:
#   $::site
#
# === Usage
#
#   $cluster_name = kafka_cluster_name($prefix)
# or
#   $cluster_name = kafka_cluster_name($prefix, 'esams')
#
# This will get you the full Kafka cluster name for the given prefix in the current $::site.
# The full kafka cluster name is either looked up in the kafka_datacenter_map in Hiera,
# OR returned as $prefix-$site.
#
# If the '::kafka_cluster_name' variable is set in Hiera, the prefix is ignored and
# the value is returned.  TODO: remove ::kafka_cluster_name support; this is no longer used
# and can cause confusion.
#
Puppet::Functions.create_function(:"kafka_cluster_name") do
  dispatch :kafka_cluster_name do
    param "String[1]", :prefix
    optional_param "Optional[String[1]]", :site
    return_type "String"
  end

  def kafka_cluster_name(prefix, site = nil)
    # If kafka_cluster_name is set in scope in hiera, then just return it.
    name =
      call_function(
        "lookup",
        "kafka_cluster_name",
        { "default_value" => :none }
      )
    return name unless name == :none

    # Otherwise build name from prefix and site.
    site ||= closure_scope["::site"]
    realm = closure_scope["::realm"]

    if realm == "labs"
      labsp = closure_scope["::wmcs_project"]
      "#{prefix}-#{labsp}"
    else
      # Else expect that the caller wants the kafka cluster for prefix in the current datacenter.
      "#{prefix}-#{site}"
    end
  end
end
