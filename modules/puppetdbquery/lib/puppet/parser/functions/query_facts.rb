Puppet::Parser::Functions.newfunction(:query_facts, :type => :rvalue, :arity => 2, :doc => <<-EOT

  accepts two arguments, a query used to discover nodes, and a list of facts
  that should be returned from those hosts.

  The query specified should conform to the following format:
    (Type[title] and fact_name<operator>fact_value) or ...
    Package[mysql-server] and cluster_id=my_first_cluster

  The facts list provided should be an array of fact names.

  The result is a hash that maps the name of the nodes to a hash of facts that
  contains the facts specified.

EOT
) do |args|
  query, facts = args

  require 'puppet/util/puppetdb'
  # This is needed if the puppetdb library isn't pluginsynced to the master
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  begin
    require 'puppetdb/connection'
  ensure
    $LOAD_PATH.shift
  end

  puppetdb = PuppetDB::Connection.new(Puppet::Util::Puppetdb.server, Puppet::Util::Puppetdb.port)
  query = puppetdb.parse_query query, :facts if query.is_a? String
  puppetdb.facts(facts, query)
end
