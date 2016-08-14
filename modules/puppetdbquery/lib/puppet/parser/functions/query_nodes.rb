Puppet::Parser::Functions.newfunction(:query_nodes, :type => :rvalue, :arity => -2, :doc => <<-EOT

  accepts two arguments, a query used to discover nodes, and a optional
  fact that should be returned.

  The query specified should conform to the following format:
    (Type[title] and fact_name<operator>fact_value) or ...
    Package["mysql-server"] and cluster_id=my_first_cluster

  The second argument should be single fact (this argument is optional)

EOT
) do |args|
  query, fact = args

  require 'puppet/util/puppetdb'
  # This is needed if the puppetdb library isn't pluginsynced to the master
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  begin
    require 'puppetdb/connection'
  ensure
    $LOAD_PATH.shift
  end

  puppetdb = PuppetDB::Connection.new(Puppet::Util::Puppetdb.server, Puppet::Util::Puppetdb.port)
  if fact then
    query = puppetdb.parse_query query, :facts if query.is_a? String
    puppetdb.facts([fact], query).each_value.collect { |facts| facts[fact] }
  else
    query = puppetdb.parse_query query, :nodes if query.is_a? String
    puppetdb.query(:nodes, query).collect { |n| n['name'] }
  end
end
