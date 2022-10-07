# SPDX-License-Identifier: Apache-2.0
# filter_on_templates.rb
# Logstash Ruby script to strip incompatible top-level fields based on type from a set of index templates
# @version 1.0.0

def register(params)
  @types_map = {  # TODO: This mapping is incomplete.  You can help by expanding it.
    'date'      => [String, DateTime],
    'keyword'   => [String, Array, Numeric],
    'text'      => [String, Numeric],
    'object'    => [Hash]
  }
  @top_level_keys = {}
  # Find all templates matching glob_pattern and sort to allow duplicate keys in later patches to overwrite older ones.
  Dir.glob(params['glob_pattern']).sort.each do | f |
    JSON.load(File.read(f))['mappings']['properties'].each do | k, v |
      v['type'] = 'object' if v['type'].nil?
      @top_level_keys[k] = @types_map[v['type']]
    end
  end
end

def filter(event)
  # Collect removed keys on reason for removal for later tracking
  no_such_field = []
  field_type_mismatch = []

  event.to_hash.each_key do | k |
    # Skip special fields
    next if k[0] == '@'

    # Remove if undefined by index template
    if @top_level_keys[k].nil?
      no_such_field.append(k)
      event.remove(k)
      next
    end

    # Remove if key does not match expected type
    unless @top_level_keys[k].include?(event.get(k).class)
      field_type_mismatch.append(k)
      event.remove(k)
    end
  end

  # Track dropped fields in normalized object
  event.set('[normalized][dropped][no_such_field]', no_such_field) unless no_such_field.empty?
  event.set('[normalized][dropped][field_type_mismatch]', field_type_mismatch) unless field_type_mismatch.empty?

  [event]
end
