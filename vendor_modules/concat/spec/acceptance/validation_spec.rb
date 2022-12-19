# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'validation, concat validate_cmd parameter', if: ['debian', 'redhat', 'ubuntu'].include?(os[:family]) do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  context 'with "/usr/bin/test -e %"' do
    let(:pp) do
      <<-MANIFEST
      concat { '#{basedir}/file':
        validate_cmd => '/usr/bin/test -e %',
      }
      concat::fragment { 'content':
        target  => '#{basedir}/file',
        content => 'content',
      }
      MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to contain 'content'
    end
  end
end
