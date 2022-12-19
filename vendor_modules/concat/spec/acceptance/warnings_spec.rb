# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'warnings' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  context 'when concat::fragment target not found' do
    let(:pp) do
      <<-MANIFEST
      concat { 'file':
        path => '#{basedir}/file',
      }
      concat::fragment { 'foo':
        target  => '#{basedir}/bar',
        content => 'bar',
      }
    MANIFEST
    end

    it 'applies manifests, check stderr' do
      expect(apply_manifest(pp, catch_failures: true).stderr).to match 'not found in the catalog'
      expect(apply_manifest(pp, catch_failures: true).stderr).to match 'not found in the catalog'
    end
  end
end
