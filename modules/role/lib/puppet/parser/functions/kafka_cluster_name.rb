# == Function: kakfa_cluster_name(string prefix[, string site])
#
# Determines the Kafka cluster name based on the supplied prefix.
# NOTE: this function is WMF-specific and takes into account the fact that the
# analytics cluster's name in production has historically been 'eqiad'
#

module Puppet::Parser::Functions
  newfunction(:kafka_cluster_name, :type => :rvalue, :arity => -2) do |args|
    name = function_hiera(['kafka_cluster_name', :none])
    return name unless name == :none
    prefix = args.pop
    realm = scope.lookupvar('realm')
    site = args.pop || scope.lookupvar('site')
    labsp = scope.lookupvar('labsproject')
    if realm == 'labs'
      "#{prefix}-#{labsp}"
    elsif prefix == 'analytics' && site == 'eqiad'
      'eqiad'
    else
      "#{prefix}-#{site}"
    end
  end
end
