# Nuyaml Hiera backend - the yaml backend with some sugar on top
#
# Based on the original yaml_backend from hiera distribution, any
# modification/addition:
# Author: Giuseppe Lavagetto <glavagetto@wikimedia.org>
# Copyright  (c) 2014 Wikimedia Foundation
#
#
# This backend allows some more flexibility over the vanilla yaml
# backend, as path expansion in the lookup and even dynamic lookups.
#
# == Private path
#
# If you define a 'private' data source in hiera, we will look up
# in a data.yaml file in the data dir we've specified as the datadir
# for a 'private' backend, or in the default datadir as a fallback.
#
# == Path expansion
#
# Any hierarchy named in the backend-configuration section
# :expand_path be expanded when looking the file up on disk. This
# allows both to have a more granular set of files, but also to avoid
# unnecessary cache evictions for cached data.
#
# === Example
#
# Say your hiera.yaml has defined
#
# :nuyaml:
#   :expand_path:
#     - module_data
#
# :hierarchy:
#   - common
#   - module_data
#
# then when searching hiera for say passwords::mysql::s1, hiera will
# first load the #{datadir}/common.yaml file and search for
# passwords::mysql::s1, then if not found, it will search for 's1'
# inside the file #{datadir}/module_data/passwords/mysql.yaml
#
# Unless very small, all files should be split up like this.
#
# == Dynamic lookup
#
# Sometimes we want to search for data based on variables... that are
# hosted within hiera! Dynamic lookup allows to define hierachies that
# will determine the full path based on results from hiera
# itself. Tricky? Let's see with an example
#
# === Example
#
# Say you have in your hiera config
# :nuyaml:
#   :dynamic_lookup:
#      - role
# :hierarchy:
#   - "host/%{fqdn}"
#   - role
#
# What will happen will be that any key we search (say $cluster) will
# be first searched in the specific file for that host
# (host/hostname.yaml), if not found, it will be searched as follows:
# - if host/hostname.yaml contains a value for role, say
#   'refrigerator', then lookup will continue in the
#  'role/refrigerator.yaml' file
# - else it will looked up in the 'role/default.yaml'
#
# Note that for added fun you may declare one part of the hierarchy to
# be both dynamically looked up and expanded. It works!
class Hiera
  module Backend
    class Nuyaml_backend

      def initialize(cache=nil)
        require 'yaml'
        @cache = cache || Filecache.new
        config = Config[:nuyaml]
        @dynlookup = config[:dynlookup] || []
        @expand_path = config[:expand_path] || []
      end

      def get_path(key, scope, source)
        config_section = :nuyaml
        # Special case: 'private' repository.
        # We use a different datadir in this case.
        # Example: private/common will search in the common source
        # within the private datadir
        if m = /private\/(.*)/.match(source)
          config_section = :private
          source = m[1]
        end

        Hiera.debug("The source is: #{source}")
        # If the source is in the expand_path list, perform path
        # expansion. This is thought to allow large codebases to live
        # with fairly small yaml files as opposed to a very large one.
        # Example:
        # $apache::mpm::worker => 'worker' in common/apache/mpm.yaml
        if @expand_path.include? source
          namespaces = key.gsub(/^::/,'').split('::')
          newkey = namespaces.pop

          unless namespaces.empty?
            source += "/".concat(namespaces.join('/'))
            key = newkey
          end
        end

        return key, Backend.datafile(config_section, scope, source, "yaml")
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Hiera.debug("Looking up #{key}")

        Backend.datasources(scope, order_override) do |source|
          # Yes this is kind of hacky. We look it up again on hiera,
          # and build a source based on the lookup.
          if @dynlookup.include? source
            Hiera.debug("Dynamic lookup for source #{source}")
            if key == source
              next
            end
            dynsource = lookup(source, scope, order_override, :priority)
            dynsource ||= 'default'
            source += "/#{dynsource}"
          end

          Hiera.debug("Loading info from #{source} for #{key}")

          lookup_key, yamlfile = get_path(key, scope, source)

          Hiera.debug("Searching for #{lookup_key} in #{yamlfile}")

          next if yamlfile.nil?

          Hiera.debug("Loading file #{yamlfile}")

          next unless File.exist?(yamlfile)

          data = @cache.read(yamlfile, Hash) do |content|
            YAML.load(content)
          end

          next if data.empty?
          next unless data.include?(lookup_key)

          # Extra logging that we found the key. This can be outputted
          # multiple times if the resolution type is array or hash but that
          # should be expected as the logging will then tell the user ALL the
          # places where the key is found.
          Hiera.debug("Found #{lookup_key} in #{source}")

          # for array resolution we just append to the array whatever
          # we find, we then goes onto the next file and keep adding to
          # the array
          #
          # for priority searches we break after the first found data
          # item

          new_answer = Backend.parse_answer(data[lookup_key], scope)
          case resolution_type
          when :array
            raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
            answer ||= []
            answer << new_answer
          when :hash
            raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer,answer)
          else
            answer = new_answer
            break
          end
        end

        return answer
      end
    end
  end
end
