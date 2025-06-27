# SPDX-License-Identifier: Apache-2.0
# convert_numeric_fields_on_templates.rb
# Logstash Ruby script to convert expected numeric fields to int/float from strings based on a provided template.
# @version 1.0.0

# The register function required by the Ruby plugin.
def register(params)
  @integers = [:long, :integer, :short, :byte, :unsigned_long]
  @floats = [:double, :float, :half_float, :scaled_float]
  @numeric_types = [].concat(@integers).concat(@floats)
  template_file = Dir.glob(params['glob_pattern']).sort.last
  @template = JSON.load(File.read(template_file))
  @dynamic_template_objects = get_dynamic_template_namespaces(@template['mappings']['dynamic_templates'])
  @numeric_namespaces = get_numerics_from_templates(@template['mappings']['properties'])
end

# Convert a string into an Integer or a Float according to expected type
# @param value [String] The value to convert.
# @param type [Symbol] The OpenSearch data type.
def convert(value, type)
  return Integer(value) if @integers.include?(type)
  Float(value)
end

# Build up a list of namespaces expecting numerics from the template.
# This is a fairly expensive operation and is meant to be cached at plugin registration.
# Warning: Recursive function.
#
# @param template [Object] The object being descended into.
# @param key [String] The hash key being handled.
# @param namespace [String] The namespace this function has built up thus far.
# @param output [Array] The response object that has built up so far.
# @return [Hash]
def get_numerics_from_templates(template, key = '', namespace = '', output = {})
  namespace = key.empty? ? '' : "#{namespace}[#{key}]"
  # If we're descending into an object with properties, skip directly into the properties object.
  if template['properties']
    template['properties'].each do |k, v|
      get_numerics_from_templates(v, k, namespace, output)
    end
    return
  end

  # If we've discovered a namespace with a type field, add it to the output.
  if template['type']
    if @numeric_types.include?(template['type'].to_sym)
      output[namespace] = { :type => template['type'].to_sym }
    end
    return
  end

  # This snippet allows us to pass in the template's mappings.properties directly
  # without iterating over the hash in register()
  if template.is_a?(Hash)
    template.each do |k, v|
      get_numerics_from_templates(v, k, namespace, output)
    end
  end
  output
end

# Build up a list of namespaces from dynamic template definitions that are int or float typed.
# Warning: only handles one globbing field, e.g. metrics.puppet.runtime.*.seconds
#
# @param dynamic_templates [Array] The list of dynamic templates.
# @return [Hash]
def get_dynamic_template_namespaces(dynamic_templates)
  output = {}
  dynamic_templates.each do |dt|
    # default ECS dynamic mapping settings as of ecs 1.11.0
    next if dt.keys.include?('strings_as_keyword')
    dt.each_value do |settings|
      next unless settings['path_match']
      # convert dot-delimited to bracketed namespace
      full_ns = "[#{settings['path_match'].gsub(/\./, '][')}]"
      parent, child = full_ns.split('[*]')
      # we'll use the parent (namespace before the glob) as the key so that we
      # can use the keys to exclude it from the list of objects
      t = settings['mapping']['type'].to_sym
      next unless @numeric_types.include?(t)
      output[parent] = {
        :type => settings['mapping']['type'].to_sym,
        :child => child
      }
    end
  end
  output
end

# The filter required by the Ruby plugin.
def filter(event)
  # Collect invalid namespaces for reporting
  errors = []

  # handle dynamic template namespaces
  @dynamic_template_objects.each do |namespace, properties|
    entity = event.get(namespace)
    next if entity.nil?
    next unless entity.is_a?(Hash)
    entity.each do |key, value|
      child_key = properties[:child].gsub(/\[|\]/, '')
      if value[child_key].is_a?(String)
        event.set("#{namespace}[#{key}][#{child_key}]", convert(entity[key][child_key], properties[:type]))
      end
    end
  end

  # handle all other namespaces
  @numeric_namespaces.each do |namespace, properties|
    entity = event.get(namespace)
    next if entity.nil?
    # only convert strings
    next unless entity.is_a?(String)
    begin
      event.set(namespace, convert(entity, properties[:type]))
    rescue
      errors.append(namespace)
      event.remove(namespace)
    end
  end

  # record errors
  event.set('[normalized][dropped][string_to_numeric_conversion_failure]', errors) unless errors.empty?
  [event]
end

# run tests with `ruby convert_numeric_fields_on_templates.rb
if __FILE__ == $PROGRAM_NAME
  require_relative '../helpers/filter_scripts_test_helper'
  require 'date_core'
  require 'bigdecimal'
  require 'bigdecimal/util'
  register({ "glob_pattern" => "../templates/ecs_1.11.0-*.json" })

  fixture = {
    'host' => {
      'uptime' => '5000' # valid
    },
    'network' => {
      'bytes' => '5k', # dropped
      'packets' => { 'foo' => 'bar' } # will pass
    },
    'process' => {
      'pid' => [1], # will pass
      'exit_code' => '1.1' # dropped: invalid float, should be int
    },
    'event' => {
      'risk_score' => '1', # should convert to float
      'risk_score_norm' => '1.5' # valid
    },
    'metrics' => {
      'puppet' => {
        'runtime' => {
          'foo' => {
            'seconds' => '5'
          },
          'bar' => {
            'seconds' => 6
          }
        }
      }
    }
  }

  event = filter(Event.new(fixture))[0]

  # print the filtered output if first argument is 'debug'
  if ARGV[0] == 'debug'
    require 'json'
    puts(JSON.pretty_generate(event.to_hash))
  end

  assert_true(
    'valid integer',
    event.get('[host][uptime]') == 5000
  )

  assert_true(
    'valid float',
    event.get('[event][risk_score_norm]').to_d == 1.5.to_d
  )

  assert_true(
    'integers convert to float',
    event.get('[event][risk_score]').to_d == 1.0.to_d
  )

  assert_true(
    'dynamic templates are converted',
    event.get('[metrics][puppet][runtime][foo][seconds]').to_d == 5.0.to_d
  )

  assert_true(
    'invalid arrays remain intact',
    event.get('[process][pid]').is_a?(Array)
  )

  assert_true(
    'invalid hashes remain intact',
    event.get('[network][packets]').is_a?(Hash)
  )

  assert_true(
    'invalid values',
    event.get('[normalized][dropped][string_to_numeric_conversion_failure]') == [
      '[network][bytes]',
      '[process][exit_code]'
    ]
  )
end
