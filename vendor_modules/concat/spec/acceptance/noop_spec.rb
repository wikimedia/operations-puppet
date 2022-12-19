# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'concat noop parameter', if: ['debian', 'redhat', 'ubuntu'].include?(os[:family]) do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'with "/usr/bin/test -e %"' do
    let(:pp) do
      <<-MANIFEST
      concat_file { '#{basedir}/file':
        noop => false,
      }
      concat_fragment { 'content':
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
