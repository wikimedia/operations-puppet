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
#
# This will get you the full Kafka cluster name for the given prefix. If the
# '::kafka_cluster_name' variable is set in Hiera, the prefix is ignored and
# the value is returned.
#

module Puppet::Parser::Functions
  newfunction(:kafka_cluster_name, :type => :rvalue, :arity => -2) do |args|
    name = function_hiera(['kafka_cluster_name', :none])
    return name unless name == :none
    prefix = args.pop
    realm = lookupvar('::realm')
    site = args.pop || lookupvar('::site')
    labsp = lookupvar('::labsproject')
    if realm == 'labs'
      "#{prefix}-#{labsp}"
    # There is only one analytics cluster, it lives in eqiad.
    # For historical reasons, the name of this cluster is 'eqiad'.
    elsif prefix == 'analytics'
      'eqiad'
    else
      "#{prefix}-#{site}"
    end
  end
end
