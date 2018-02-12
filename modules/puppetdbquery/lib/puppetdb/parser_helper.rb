# Helper methods for the parser, included in the parser class
require 'puppetdb'
module PuppetDB::ParserHelper
  # Parse a query string into a PuppetDB query
  #
  # @param query [String] the query string to parse
  # @param endpoint [Symbol] the endpoint for which the query should be evaluated
  # @return [Array] the PuppetDB query
  def parse(query, endpoint = :nodes)
    if query = scan_str(query)
      query.optimize.evaluate [endpoint]
    end
  end

  # Create a query for facts on nodes matching a query string
  #
  # @param query [String] the query string to parse
  # @param facts [Array] an array of facts to get
  # @return [Array] the PuppetDB query
  def facts_query(query, facts = nil)
    nodequery = parse(query, :facts)
    if facts.nil?
      nodequery
    else
      factquery = ['or', *facts.collect { |f|
         if (f =~ /^\/(.+)\/$/)
            ['~', 'name', f.scan(/^\/(.+)\/$/).last.first]
         else
            ['=', 'name', f]
         end
      }]
      if nodequery
        ['and', nodequery, factquery]
      else
        factquery
      end
    end
  end

  # Turn an array of facts into a hash of nodes containing facts
  #
  # @param fact_hash [Array] fact values
  # @param facts [Array] fact names
  # @return [Hash] nodes as keys containing a hash of facts as value
  def facts_hash(fact_hash, facts)
    fact_hash.reduce({}) do |ret, fact|
      # Array#include? only matches on values of the same type, so if we find
      # a matching string, it's not a nested query.
      name, value = if facts.include?(fact['name']) || facts == [:all] ||
                      # in case a regex pattern is used in the facts query
                      facts.index{ |factname| factname =~ /^\/(.+)\/$/ && Regexp.new(factname.match(/^\/(.+)\/$/)[1]).match(fact['name']) }

                      [fact['name'], fact['value']]
                    else
                      # Find the set of keys where the first value is the fact name
                      nested_keys = facts.select do |x|
                        x.is_a?(Array) && x.first == fact['name']
                      end.flatten

                      # Join all the key names together with an underscore to give
                      # us a unique name, and then send all the keys but the fact
                      # name (which was already queried out) to extract_nested_fact
                      [
                        nested_keys.join("_"),
                        extract_nested_fact([fact], nested_keys[1..-1]).first
                      ]
                    end

      if ret.include? fact['certname']
        ret[fact['certname']][name] = value
      else
        ret[fact['certname']] = { name => value }
      end
      ret
    end
  end

  # Take an array of hashes of fact hashes and get a nested value from each
  # of them.
  #
  # @param fact_hashes [Array] an array of hashes of fact hashes
  # @param keys [Array] an array of keys to dig into the hash
  # @returt [Array] an array of extracted values
  def extract_nested_fact(fact_hashes, keys)
    fact_hashes.map do |fact_hash|
      hash = fact_hash['value']

      # Traverse the hash, setting `hash` equal to the next level deep each step
      keys[0..-2].each do |key|
        hash = hash.fetch(key, {})
      end

      # Lookup the final key. This will convert to nil if we've been defaulting
      # to empty hash beforehand.
      hash[keys.last]
    end
  end

  # Turn a query into one for only certain fields
  def self.extract(*field, query)
    ['extract', field.collect(&:to_s), query]
  end
end
