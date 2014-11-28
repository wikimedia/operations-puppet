class Hiera
  module Backend
    class Role_backend
      def initialize(cache=nil)
        require 'yaml'
        @cache = cache || Filecache.new
        config = Config[:role]
      end

      def get_path(key, role, source)
        # Variables for role::foo::bar will be searched in:
        # role/foo/bar.yaml
        # role/$::site/foo/bar.yaml
        # etc, depending on your hierarchy
        path = role.gsub(/^::/,'').split('::').shift().join('/')
        if source == 'common'
          src = "role/#{path}"
        else
          src = "role/#{source}/#{path}"
        end
        return Backend.datafile(:role, scope, src, "yaml")
      end

      def merge_answer(new_answer, answer, resolution_type)
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
          return true
        end
        return false
      end

      def lookup(key, scope, order_override, resolution_type)
        topscope_var = '::role'
        resultset = nil
        return unless scope.include?topscope_var
        roles = scope[topscope_var]
        hierarchy = Config.include?[:role_hierarchy] ? Config[:role_hierachy] : nil
        roles.keys.each do |role|
          answer = nil
          Backend.datasources(scope,order_override,hierarchy) do |source|
            file = get_path(key,role,source)
            next if yamlfile.nil?
            Hiera.debug("Searching in #{file} for #{key}")
            next unless File.exist?(yamlfile)

            data = @cache.read(yamlfile, Hash) do |content|
              YAML.load(content)
            end
            next if data.empty?
            next unless data.include? key
            new_answer = Backend.parse_answer(data[key], scope)
            Hiera.debug("Found: #{key} =>  #{new_answer}")
            break if merge_answer(new_answer, answer, resolution_type)
          end
          # Now we got one answer for this role, we can merge it with what we got earlier.
          case resolution_type
          when :array
            resultset ||= []
            resultset << answer
          when :hash
            resultset ||= {}
            resultset = Backend.merge_answer(answer, resultset)
          else
            # We raise an exception if we have received conflicting results
            if resultset and answer != resultset
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
