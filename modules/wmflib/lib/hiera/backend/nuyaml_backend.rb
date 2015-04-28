# Nuyaml Hiera backend - the yaml backend with some sugar on top
#
# Based on the original yaml_backend from hiera distribution, any
# modification/addition:
# Author: Giuseppe Lavagetto <glavagetto@wikimedia.org>
# Copyright  (c) 2014 Wikimedia Foundation
#
#
# This backend allows some more flexibility over the vanilla yaml
# backend, as path expansion in the lookup.
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
# == Regexp matching
#
# As multiple hosts may correspond to the same rules/configs in a
# large cluster, we allow to define a self-contained "regex.yaml" file
# in your datadir, where each different class of servers may be
# represented by a label and a corresponding regexp.
#
# === Example
# Say you have a lookup for "cluster", and you have
#"regex/%{hostname}" in your hierarchy; also, let's say that your
# scope contains hostname = "web1001.local". So if your regex.yaml
# file contains:
#
# databases:
#   __regex: !ruby/regex '/db.*\.local/'
#   cluster: db
#
# webservices:
#   __regex: !ruby/regex '/^web.*\.local$/'
#   cluster: www
#
# This will make it so that "cluster" will assume the value "www"
# given the regex matches the "webservices" stanza
#
class Hiera
  module Backend
    class Nuyaml_backend

      def initialize(cache=nil)
        require 'yaml'
        @cache = cache || Filecache.new
        config = Config[:nuyaml]
        @expand_path = config[:expand_path] || []
      end

      def get_path(key, scope, source)
        config_section = :nuyaml
        # Special case: regex
        if m = /^regex\//.match(source)
          Hiera.debug("Regex match going on - using regex.yaml")
          return key, Backend.datafile(config_section, scope, 'regex', "yaml")
        end

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
        paths = @expand_path.map{ |x| Backend.parse_string(x, scope) }
        if paths.include? source
          namespaces = key.gsub(/^::/,'').split('::')
          newkey = namespaces.pop

          unless namespaces.empty?
            source += "/".concat(namespaces.join('/'))
            key = newkey
          end
        end

        return key, Backend.datafile(config_section, scope, source, "yaml")
      end

      def plain_lookup(key, data, scope)
          return nil unless data.include?(key)
          return Backend.parse_answer(data[key], scope)
      end

      def regex_lookup(key, matchon, data, scope)
        data.each do |label, datahash|
          r = datahash["__regex"]
          Hiera.debug("Scanning label #{label} for matches to '#{r}' in '#{matchon}' ")
          next unless r.match(matchon)
          Hiera.debug("Label #{label} matches; searching within it")
          next unless datahash.include?(key)
          return Backend.parse_answer(datahash[key], scope)
        end
        return nil
      rescue => detail
        Hiera.debug(detail)
        return nil
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Hiera.debug("Looking up #{key}")

        Backend.datasources(scope, order_override) do |source|
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

          if m = /regex\/(.*)$/.match(source)
            matchto = m[1]
            new_answer = regex_lookup(lookup_key, matchto, data, scope)
          else
            new_answer = plain_lookup(lookup_key, data, scope)
          end
          next if new_answer.nil?
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
