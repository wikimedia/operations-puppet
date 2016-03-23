# == Function: kakfa_cluster_name(string prefix)
#
# Determines the Kafka cluster name based on the supplied prefix.
# NOTE: this function is WMF-specific and takes into account the fact that the
# analytics cluster's name in production has historically been 'eqiad'
#

module Puppet::Parser::Functions
  newfunction(:kafka_cluster_name, :type => :rvalue, :arity => 1) do |args|
    prefix = args.pop
    name = function_hiera ['kafka_cluster_name']
    return name if name
    realm = scope.lookup_var 'realm'
    site = scope.lookup_var 'site'
    labsp = scope.lookup_var 'labsproject'
    if realm == 'labs'
      "#{prefix}-#{labsp}"
    elsif prefix == 'analytics'
      'eqiad'
    else
      "#{prefix}-#{site}"
    end
  end
end
