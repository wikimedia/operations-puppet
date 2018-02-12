class Hiera
  module Backend
    class Puppetdb_backend
      def initialize
        require 'puppetdb/connection'
        begin
          require 'puppet'
          # This is needed when we run from hiera cli
          Puppet.initialize_settings unless Puppet[:confdir]
          require 'puppet/util/puppetdb'
          PuppetDB::Connection.check_version
          uri = URI(Puppet::Util::Puppetdb.config.server_urls.first)
          host = uri.host
          port = uri.port
          ssl = uri.scheme == 'https'
        rescue
          host = 'puppetdb'
          port = 443
          ssl = true
        end

        Hiera.debug('Hiera PuppetDB backend starting')

        @puppetdb = PuppetDB::Connection.new(host, port, ssl)
        @parser = PuppetDB::Parser.new
      end

      def lookup(key, scope, order_override, _resolution_type)
        return nil if key.end_with? '::_nodequery'

        Hiera.debug("Looking up #{key} in PuppetDB backend")

        if nodequery = Backend.lookup(key + '::_nodequery', nil, scope, order_override, :priority)
          Hiera.debug("Found nodequery #{nodequery.inspect}")

          # Support specifying the query in a few different ways
          if nodequery.is_a? Hash
            query = nodequery['query']
            fact = nodequery['fact']
          elsif nodequery.is_a? Array
            query, fact = *nodequery
          else
            query = nodequery.to_s
          end

          if fact
            query = @parser.facts_query query, [fact]
            @puppetdb.query(:facts, query).collect { |f| f['value'] }.sort
          else
            query = @parser.parse query, :nodes if query.is_a? String
            @puppetdb.query(:nodes, query).collect { |n| n['name'] }
          end
        end
      end
    end
  end
end
