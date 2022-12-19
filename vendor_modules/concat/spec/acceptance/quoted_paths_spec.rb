# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'quoted paths' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'with path with blanks' do
    let(:pp) do
      <<-MANIFEST
        file { '#{basedir}/concat test':
          ensure => directory,
        }
        concat { '#{basedir}/concat test/foo':
        }
        concat::fragment { '1':
          target  => '#{basedir}/concat test/foo',
          content => 'string1',
        }
        concat::fragment { '2':
          target  => '#{basedir}/concat test/foo',
          content => 'string2',
        }
      MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp)
      expect(file("#{basedir}/concat test/foo")).to be_file
      expect(file("#{basedir}/concat test/foo").content).to match %r{string1string2}
    end
  end
end
