require 'yaml'

Puppet::Functions.create_function(:'wmflib::expand_path') do
  dispatch :expand_path do
    param 'String[1]', :key
    param 'Struct[{path=>String[1]}]', :options
    param 'Puppet::LookupContext', :context
  end

  def expand_path(key, options, context)
    return context.cached_value(key) if context.cache_has_key(key)
    base_path = options['path']
    namespace = key.gsub(/^::/, '').split('::')
    namespace.pop
    if namespace.empty?
      expanded_path = "#{base_path}.yaml"
    else
      expanded_path = File.join(base_path, namespace) + '.yaml'
    end
    data = load_data_hash(expanded_path, context)
    context.not_found unless data.include?(key)
    context.cache(key, context.interpolate(data[key]))
  end

  def load_data_hash(path, context)
    return {} unless File.exists?(path)
    context.cached_file_data(path) do |content|
      begin
        if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7')
          data = YAML.safe_load(content, filename: path, aliases: true)
        else
          data = YAML.load(content, path)
        end
        if data.is_a?(Hash)
          if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7')
            data
          else
            Puppet::Pops::Lookup::HieraConfig.symkeys_to_string(data)
          end
        else
          msg = format(_("%{path}: file does not contain a valid yaml hash"), path: path)
          raise Puppet::DataBinding::LookupError, msg if Puppet[:strict] == :error && data != false
          Puppet.warning(msg)
          {}
        end
      rescue Yaml::SyntaxError => ex
        # YamlLoadErrors include the absolute path to the file, so no need to add that
        raise Puppet::DataBinding::LookupError, format(_("Unable to parse %{message}"), message: ex.message)
      end
    end
  end
end
