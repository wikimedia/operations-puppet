# Accepts two arguments, a query used to discover nodes, and an optional
# fact that should be returned.
#
# The query specified should conform to the following format:
#   (Type[title] and fact_name<operator>fact_value) or ...
#    Package["mysql-server"] and cluster_id=my_first_cluster
#
# The second argument should be single fact or series of keys joined on periods
# (this argument is optional)
Puppet::Functions.create_function('query_nodes') do
  require 'puppet/util/puppetdb'

  # This is needed if the puppetdb library isn't pluginsynced to the master
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
  begin
    require 'puppetdb/connection'
  ensure
    $LOAD_PATH.shift
  end

  dispatch :query_nodes do
    param 'Variant[String, Array]', :query
  end

  dispatch :query_nodes_fact do
    param 'Variant[String, Array]', :query
    param 'String', :fact
  end

  def parser
    @parser ||= PuppetDB::Parser.new
  end

  def puppetdb
    @uri ||= URI(Puppet::Util::Puppetdb.config.server_urls.first)
    @puppetdb ||= PuppetDB::Connection.new(
      @uri.host,
      @uri.port,
      @uri.scheme == 'https'
    )
  end

  def query_nodes(query)
    query = parser.parse(query, :nodes) if query.is_a? String
    puppetdb.query(:nodes, query, :extract => :certname).collect do |n|
      n['certname']
    end
  end

  def query_nodes_fact(query, fact)
    fact_for_query = fact.split('.').first

    query = parser.facts_query(query, [fact_for_query])
    response = puppetdb.query(:facts, query, :extract => :value)

    if fact.split('.').size > 1
      parser.extract_nested_fact(response, fact.split('.')[1..-1])
    else
      response.collect { |f| f['value'] }
    end
  end
end
