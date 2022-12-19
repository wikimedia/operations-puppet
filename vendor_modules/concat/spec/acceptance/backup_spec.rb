# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'concat backup parameter' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'when puppet' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/file':
          backup => 'puppet',
        }
        concat::fragment { 'new file':
          target  => '#{basedir}/file',
          content => 'new contents',
        }
      MANIFEST
    end

    it 'applies the manifest twice with "Filebucketed" stdout and no stderr' do
      expect(apply_manifest(pp, catch_failures: true, debug: true).stdout).to match(%r{Filebucketed.*to puppet with sum.*})
      apply_manifest(pp, catch_changes: true)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match %r{new contents}
    end
  end

  describe 'when .backup' do
    let(:pp) do
      <<-MANIFEST
      concat { '#{basedir}/file':
        backup => '.backup',
      }
      concat::fragment { 'new file':
        target  => '#{basedir}/file',
        content => 'backup extension',
      }
      MANIFEST
    end

    # XXX Puppet doesn't mention anything about filebucketing with a given
    # extension like .backup
    it 'applies the manifest twice no stderr' do
      idempotent_apply(pp)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match %r{backup extension}
      expect(file("#{basedir}/file.backup")).to be_file
      expect(file("#{basedir}/file.backup").content).to match %r{new contents}
    end
  end

  # XXX The backup parameter uses validate_string() and thus can't be the
  # boolean false value, but the string 'false' has the same effect in Puppet 3
  describe "when 'false'" do
    let(:pp) do
      <<-MANIFEST
      concat { '#{basedir}/file':
        backup => '.backup',
      }
      concat::fragment { 'new file':
        target  => '#{basedir}/file',
        content => 'new contents',
      }
    MANIFEST
    end

    it 'applies the manifest twice with no "Filebucketed" stdout and no stderr' do
      apply_manifest(pp, catch_failures: true) do |r|
        expect(r.stdout).not_to match(%r{Filebucketed})
      end
      apply_manifest(pp, catch_changes: true)
      expect(file("#{basedir}/file")).to be_file
      expect(file("#{basedir}/file").content).to match %r{new contents}
    end
  end
end
