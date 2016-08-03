# Role-based Hiera backend
#
# Author: Giuseppe Lavagetto <glavagetto@wikimedia.org>
# Copyright  (c) 2014 Wikimedia Foundation
#
#
# This backend allows to group definitions based on the roles defined
# at the node level using the 'role' keyword.
# It allows searching in hierarchies that are based on the role
# currently applied; this is very handy if you have group of hosts
# whose configuration is dependent on their role rather than on other
# facts like hostnames.
#
# == How this works
#
# Whenever you use the 'role' keyword in a node:
#
#   role cache::text
#
# Two things happen:
# - the class role::cache::text gets included in the current node
# - this gets registered in a global registry
#
# Whenever a hiera lookup is performed and the role backend is used,
# the key is searched in all the hierarchies defined in the
# :role_hierarchy.
#
# A typical hierarchy would be:
# - "%{::environment}"
# - common
#
# The path in which the files must be is as follows:
# role/${hierarchy}/<path>.yaml
# where <path> corresponds to the argument passed to the 'role'
# keyword.
#
# === Example
#
# In site.pp:
#
# node /pinkunicorn.wikimedia.org/ {
#      role foo::bar, fizzbuzz
#      notice(hiera('admin::groups'))
# }
#
# Give the hierarchy from before, the final hiera lookup will result
# in searching admin::groups in two distinct hierarchies:
#
# role/production/foo/bar.yaml
# role/common/foo/bar.yaml
#
# role/production/fizzbuzz.yaml
# role/common/fizzbuzz.yaml
#
# The research will be performed for *both* hierarchies as a normal
# hiera lookup; if a plain lookup is performed, the results of the two
# searches will be compared; if they differ, an exception will be
# thrown, so that conflicting directives will need manual resolution.
#
# === Things to pay attention to
#
# One big caveat: if you do use multiple times the role keyword, any
# class included by the first role keyword is declared  would be
# evaluated just after the first "role" has been called, thus
# not having the full scope of both to search from; this could result
# in unexpected behaviour so I advice _against_ using multiple role
# keywords in a single node, if both roles include conflicting
# classes.
require 'yaml'
class Hiera
  module Backend
    class Role_backend
      def initialize(cache=nil)
        @cache = cache || Filecache.new
      end

      def get_path(key, role, source, scope)
        config_section = :role

        # Special case: 'private' repository.
        # We use a different datadir in this case.
        # Example: private/common will search in the role/common source
        # within the private datadir
        if m = /private\/(.*)/.match(source)
          config_section = :private
          source = m[1]
        end

        # Variables for role::foo::bar will be searched in:
        # role/foo/bar.yaml
        # role/$::site/foo/bar.yaml
        # etc, depending on your hierarchy
        path = role.split('::').join('/')
        src = "role/#{source}/#{path}"

        # Use the datadir for the 'role' section of the config
        return Backend.datafile(config_section, scope, src, "yaml")
      end

      def merge_answer(new_answer, answer, resolution_type)
        case resolution_type
        when :array
          raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of?(Array) || new_answer.kind_of?(String)
          answer ||= []
          answer << new_answer
        when :hash
          raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
          answer ||= {}
          answer = Backend.merge_answer(new_answer,answer)
        else
          answer = new_answer
          return true, answer
        end
        return false, answer
      end

      def lookup(key, scope, order_override, resolution_type)
        topscope_var = '_roles'
        resultset = nil
        return nil unless scope.include?topscope_var
        roles = scope[topscope_var]
        return nil if roles.nil?
        if Config.include?(:role_hierarchy)
          hierarchy = Config[:role_hierarchy]
        else
          hierarchy = nil
        end

        roles.keys.each do |role|
          Hiera.debug("Looking in hierarchy for role #{role}")
          answer = nil
          Backend.datasources(scope, order_override, hierarchy) do |source|
            yamlfile = get_path(key,role,source, scope)
            next if yamlfile.nil?
            Hiera.debug("Searching in file #{yamlfile} for #{key}")
            next unless File.exist?(yamlfile)

            data = @cache.read(yamlfile, Hash) do |content|
              YAML.load(content)
            end

            next if data.nil? || data.empty?

            next unless data.include? key

            new_answer = Backend.parse_answer(data[key], scope)
            Hiera.debug("Found: #{key} =>  #{new_answer}")
            is_done, answer = merge_answer(new_answer, answer,
                                           resolution_type)
            break if is_done
          end
          # skip parsing if no answer was found.
          next if answer.nil?

          # Now we got one answer for this role, we can merge it with
          # what we got earlier.
          case resolution_type
          when :array
            resultset ||= []
            answer.each { |el| resultset.push(el) }
          when :hash
            resultset ||= {}
            resultset = Backend.merge_answer(answer, resultset)
          else
            # We raise an exception if we have received conflicting results
            if resultset && answer != resultset
              raise Exception, "Conflicting value for #{key} found in role #{role}"
            else
              resultset = answer
            end
          end
        end
        resultset
      end
    end
  end
end
