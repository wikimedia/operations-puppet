# SPDX-License-Identifier: Apache-2.0
require 'set'
# create a simple object to mimic the puppet type Netbase::Service
class Service
  attr_reader :name, :port, :protocols, :aliases

  def initialize(name, data, strict)
    @name = name
    @port = data['port']
    @protocols = data['protocols']
    @portend = data.fetch('portend', nil)
    @aliases = data.fetch('aliases', []).to_set
    @description = data.fetch('description', nil)
    # This allow us to either compare via proto and port or just port
    # it's not great having this in the object class but it allows us to
    # abuse set comparisons
    @strict = strict
  end

  # override ==, eq? and hash to allow use to do set comparisons
  # == is not strictly required for set comparisons but make sense
  # to also include this
  def ==(other)
    hash == other.hash
  end

  def eql?(other)
    hash == other.hash
  end

  def hash
    if @strict
      "#{@port}_#{@protocols.join}".hash
    else
      @port.hash
    end
  end

  def puppet_type
    result = {
      'protocols' => @protocols,
      'port' => @port,
    }
    result['portend'] = @portend unless @portend.nil?
    result['description'] = @description unless @description.nil?
    result['aliases'] = @aliases.to_a unless @aliases.empty?
    result
  end
end
# @summary
#   This functions merges two Hashs of Netbase::Service's. The merge performed compares either
#   the port or the port+protocol values (depending on the strict value) as opposed to just merging
#   on the hash key, which is the default for both puppet and ruby.  We also have the ability to
#   append aliases into the winning match
# @param
#   values A hash of staring values
# @param
#   overrides A hash of override values, if entries exist in both values and override the ones
#   in overrides win
# @param
#   append_aliases If true append the name and aliases of losing matches to the corresponding
#   entry in overrides
# @param strict
#   if strict is true the check equality by comparing the port and protocol, if strict is
#   false compare only the port
# @example
#   $values    = {'foo' => {'port' => 25, 'protocols' => ['tcp'], 'aliases' => ['bar']}}
#   $overrides = {'smtp' => {'port' => 25, 'protocols' => ['tcp'], 'aliases' => ['mail']}}
#
#   $results = $values.netbase::merge($overrides)
#   $results = {'smtp' => {'port' => 25, 'protocols' => ['tcp'], 'aliases' => ['mail']}}
#
#   $results = $values.netbase::merge($overrides, append_aliases => true)
#   $results = {'smtp' => {'port' => 25, 'protocols' => ['tcp'], 'aliases' => ['mail', 'foo', 'bar']}}
#
#   $values    = {'https' => {'port' => 443, 'protocols' => ['tcp', udp']}}
#   $overrides = {'api-https' => {'port' => 443, 'protocols' => ['tcp']}}
#
#   $results = $values.netbase::merge($overrides)
#   $results == {'https' => {'port' => 443, 'protocols' => ['tcp', udp']}, 'api-https' => {'port' => 443, 'protocols' => ['tcp']}}
#
#   $results = $values.netbase::merge($overrides, strict => false)
#   $results == {'https' => {'port' => 443, 'protocols' => ['tcp', udp']}, 'api-https' => {'port' => 443, 'protocols' => ['tcp']}}
Puppet::Functions.create_function(:'netbase::services::merge', Puppet::Functions::InternalFunction) do
  dispatch :merge do
    param 'Hash[String,Netbase::Service]', :values
    param 'Hash[String,Netbase::Service]', :overrides
    optional_param 'Boolean', :append_aliases
    optional_param 'Boolean', :strict
    return_type 'Hash[String,Netbase::Service]'
  end
  def merge(values, overrides, append_aliases = false, strict = true)
    _values = Set[]
    _overrides = Set[]
    results = {}
    # To make it easier to compare the values we convert the hashes into
    # Sets of `Service` objects
    values.each { |k, v| _values.add(Service.new(k, v, strict)) }
    overrides.each { |k, v| _overrides.add(Service.new(k, v, strict)) }
    # Merge the objects
    # As the objects are sets the will call `Service.eq?` to perform the equality test
    # This means that depending on the strict value we will only compare either the
    # the port+protocol (strict: true) or just the port (strict: false).
    # Had we just tried to merge the hashes then only the hash key would be considered
    # which is undesirable
    _overrides.merge(_values).each do |override|
      # We remap the results back into a hash in the form puppet expects e.g.
      # Hash[String,Netbase::Service]
      results[override.name] = override.puppet_type
    end
    # If append overrides is true we want to add the `aliases` and `name` from
    # `value` to there matching element in `override`.  e.g.
    # if:   _values    = [Service(name: ftp, port: 21, protocols: ['tcp'])]
    # and:  _overrides = [Service(name: unicorn, port: 21, protocols: ['tcp'])]
    # then: results    = {unicorn: {port: 21, protocols: ['tcp'], aliases: ['ftp']}}
    # Further
    # if:   _values    = [Service(name: foo, port: 25, protocols: ['tcp'], aliases: ['bar'])]
    # and:  _overrides = [Service(name: smtp, port: 25, protocols: ['tcp'], aliases: ['mail'])]
    # then: results    = {smtp: {port: 25, protocols: ['tcp'], aliases: ['mail', 'foo', 'bar']}}
    if append_aliases
      _overrides.each do |override|
        results[override.name] = override.puppet_type
        next unless _values.include?(override)
        # The sets are not quite the same i.e. they are only matched on port
        # or port/protocol.  This allows use to get the "matching" element from
        # _values so we can inspect the other elements
        value = Set[override].intersection(_values).to_a[0]
        # Reconstruct the aliases from scratch
        # with a.merge(b); b is preferred
        # As such we add the values then the overrides
        aliases = Set[value.name]
        aliases.merge(value.aliases) unless value.aliases.empty?
        aliases.merge(override.aliases) unless override.aliases.empty?
        aliases.delete(override.name)
        results[override.name]['aliases'] = aliases.to_a unless aliases.empty?
      end
    end
    results
  end
end
