require 'yaml'

Puppet::Functions.create_function(:'wmflib::regex_data') do
  dispatch :regex_data do
    param 'String[1]', :key
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def regex_data(key, options, context)
    return context.cached_value(key) if context.cache_has_key(key)
    path = options['path']
    node = options['node']
    data = load_data_hash(path, context)
    regex_lookup(key, node, data, context)
  end

  def load_data_hash(path, context)
    context.cached_file_data(path) do |content|
      begin
        if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7')
          data = YAML.safe_load(content, permitted_classes: [Regexp], filename: path, aliases: true)
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
      rescue YAML::SyntaxError => ex
        # YamlLoadErrors include the absolute path to the file, so no need to add that
        raise Puppet::DataBinding::LookupError, format(_("Unable to parse %{message}"), message: ex.message)
      end
    end
  end

  def regex_lookup(key, matchon, data, context)
    data.each do |label, datahash|
      r = datahash["__regex"]
      Puppet.debug("Scanning label #{label} for matches to '#{r}' in '#{matchon}' ")
      next unless r.match(matchon)
      Puppet.debug("Label #{label} matches; searching within it")
      next unless datahash.include?(key)
      return context.cache(key, context.interpolate(datahash[key]))
    end
    return context.not_found
  rescue => detail
    Puppet.debug(detail)
    return nil
  end
end
