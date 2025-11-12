# SPDX-License-Identifier: Apache-2.0
module PuppetX
  module Pontoon
    module Helper
      def self.load_rolemap
        # Accessing the enviroment from puppet functions doesn't seem to be a thing, hence this function
        # is ruby
        stack_file = ENV['PONTOON_STACK_FILE'] || '/etc/pontoon/stack'
        pontoon_home = ENV['PONTOON_HOME'] || '/srv/git/operations/puppet/modules/pontoon/files'

        fail("Pontoon stack file #{stack_file} not found") unless File.exist?(stack_file)

        pontoon_stack = File.read(stack_file).chop
        rolemap_path = File.join(pontoon_home, pontoon_stack, 'rolemap.yaml')

        fail("Rolemap #{rolemap_path} not found") unless File.exist?(rolemap_path)

        YAML.load_file(rolemap_path)
      end
    end
  end
end
