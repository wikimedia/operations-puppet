require 'puppetdb'

class PuppetDB::Connection
  require 'rubygems'
  require 'puppetdb/parser'
  require 'uri'
  require 'puppet'
  require 'puppet/util/logging'

  include Puppet::Util::Logging

  def initialize(host = 'puppetdb', port = 443, use_ssl = true)
    @host = host
    @port = port
    @use_ssl = use_ssl
  end

  def self.check_version
    require 'puppet/util/puppetdb'
    unless Puppet::Util::Puppetdb.config.respond_to?('server_urls')
      Puppet.warning <<-EOT
It looks like you are using a PuppetDB version < 3.0.
This version of puppetdbquery requires at least PuppetDB 3.0 to work.
Downgrade to puppetdbquery 1.x to use it with PuppetDB 2.x.
EOT
    end
  rescue LoadError
  end

  # Execute a PuppetDB query
  #
  # @param endpoint [Symbol] :resources, :facts or :nodes
  # @param query [Array] query to execute
  # @param options [Hash] specify extract values or http connection
  # @return [Array] the results of the query
  def query(endpoint, query = nil, options = {}, version = :v4)
    require 'json'

    default_options = {
      :http => nil,   # A HTTP object to be used for the connection
      :extract => nil # An array of fields to extract
    }

    if options.is_a? Hash
      options = default_options.merge options
    else
      Puppet.deprecation_warning 'Specify http object with :http key instead'
      options = default_options.merge(:http => options)
    end
    http = options[:http]

    unless http
      require 'puppet/network/http_pool'
      http = Puppet::Network::HttpPool.http_instance(@host, @port, @use_ssl)
    end
    headers = { 'Accept' => 'application/json' }

    if options[:extract]
      query = PuppetDB::ParserHelper.extract(*Array(options[:extract]), query)
    end

    uri = "/pdb/query/#{version}/#{endpoint}"
    uri += URI.escape "?query=#{query.to_json}" unless query.nil? || query.empty?

    debug("PuppetDB query: #{query.to_json}")

    resp = http.get(uri, headers)
    fail "PuppetDB query error: [#{resp.code}] #{resp.msg}, query: #{query.to_json}" unless resp.is_a?(Net::HTTPSuccess)
    JSON.parse(resp.body)
  end
end
