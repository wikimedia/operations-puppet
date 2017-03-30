# == Function: mediawiki_active_dc()
#
# Copyright (c) 2017 Wikimedia foundation Inc.
#
# WMF specific function that allows to find out which is the active datacenter for
# mediawiki using dns discovery. This is admittedly a hack and shouldn't be used outside of
# its current realm of application.
#
# It is still better than having a pre-ordered global variable (mw_primary) for this.
# TODO: re-engineer puppet (if possible) to delegate to confd the functionality
module Puppet::Parser::Functions
  newfunction(:mediawiki_active_dc, :type => :rvalue, :arity => 0) do
    discovery_host = 'appservers-rw.discovery.wmnet'
    dc_data = scope.function_hiera(['ganglia_clusters'])
    datacenters = {}
    dc_data['appserver'].sites.keys.each do |dc|
      ip = scope.function_ipresolve(["appservers.svc.#{dc}.wmnet", '4'])
      datacenters[ip] = dc
    end
    active_ip = scope.function_ipresolve([discovery_host, '4'])
    datacenters[active_ip]
  end
end
