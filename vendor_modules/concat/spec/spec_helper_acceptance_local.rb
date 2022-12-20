# frozen_string_literal: true

require 'singleton'

class LitmusHelper
  include Singleton
  include PuppetLitmus
end

def setup_test_directory
  basedir = case os[:family]
            when 'windows'
              'c:/concat_test'
            else
              '/tmp/concat_test'
            end
  pp = <<-MANIFEST
    file { '#{basedir}':
      ensure  => directory,
      force   => true,
      purge   => true,
      recurse => true,
    }
    file { '#{basedir}/file':
      content => "file exists\n",
      force   => true,
    }
  MANIFEST
  LitmusHelper.instance.apply_manifest(pp, expect_failures: false)
  basedir
end
