# Accepts two arguments, a query used to discover nodes, and a list of facts
# that should be returned from those hosts.
#
# The query specified should conform to the following format:
#   (Type[title] and fact_name<operator>fact_value) or ...
#   Package[mysql-server] and cluster_id=my_first_cluster
#
# The facts list provided should be an array of fact names.
#
# The result is a hash that maps the name of the nodes to a hash of facts that
# contains the facts specified.
Puppet::Functions.create_function('query_facts')  do
  require 'puppet/util/puppetdb'

  # This is needed if the puppetdb library isn't pluginsynced to the master
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
  begin
    require 'puppetdb/connection'
  ensure
    $LOAD_PATH.shift
  end

  dispatch :query_facts do
    param 'Variant[String, Array]', :query
    param 'Array[String, 1]', :facts
  end

  def query_facts(query, facts)
    facts = facts.map { |fact| fact.match(/\./) ? fact.split('.') : fact }
    facts_for_query = facts.map { |fact| fact.is_a?(Array) ? fact.first : fact }

    uri = URI(Puppet::Util::Puppetdb.config.server_urls.first)
    puppetdb = PuppetDB::Connection.new(uri.host, uri.port, uri.scheme == 'https')
    parser = PuppetDB::Parser.new
    query = parser.facts_query query, facts_for_query if query.is_a? String
    parser.facts_hash(puppetdb.query(:facts, query, :extract => [:certname, :name, :value]), facts)
  end
end
