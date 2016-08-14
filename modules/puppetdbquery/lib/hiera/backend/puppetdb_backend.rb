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
          server = Puppet::Util::Puppetdb.server
          port = Puppet::Util::Puppetdb.port
        rescue
          server = 'puppetdb'
          port = 443
        end

        Hiera.debug("Hiera PuppetDB backend starting")

        @puppetdb = PuppetDB::Connection.new(server, port)
      end

      def lookup(key, scope, order_override, resolution_type)
        return nil if key.end_with? "::_nodequery"

        Hiera.debug("Looking up #{key} in PuppetDB backend")

        if nodequery = Backend.lookup(key + "::_nodequery", nil, scope, order_override, :priority)
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

          if fact then
            query = @puppetdb.parse_query query, :facts if query.is_a? String
            @puppetdb.facts([fact], query).each_value.collect { |facts| facts[fact] }.sort
          else
            query = @puppetdb.parse_query query, :nodes if query.is_a? String
            @puppetdb.query(:nodes, query).collect { |n| n['name'] }
          end
        end
      end
    end
  end
end
