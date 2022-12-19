# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'concat::fragment replace' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'when run should create fragment files' do
    let(:pp1) do
      <<-MANIFEST
      concat { '#{basedir}/foo': }
      concat::fragment { '1':
        target  => '#{basedir}/foo',
        content => 'caller has replace unset run 1',
      }
    MANIFEST
    end
    let(:pp2) do
      <<-MANIFEST
      concat { '#{basedir}/foo': }
      concat::fragment { '1':
        target  => '#{basedir}/foo',
        content => 'caller has replace unset run 2',
      }
    MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp1)
      idempotent_apply(pp2)
      expect(file("#{basedir}/foo")).to be_file
      expect(file("#{basedir}/foo").content).not_to match 'caller has replace unset run 1'
      expect(file("#{basedir}/foo").content).to match 'caller has replace unset run 2'
    end
  end
  # should create fragment files

  describe 'when run should replace its own fragment files when caller has File { replace=>true } set' do
    let(:pp1) do
      <<-MANIFEST
      File { replace=>true }
      concat { '#{basedir}/foo': }
      concat::fragment { '1':
        target  => '#{basedir}/foo',
        content => 'caller has replace true set run 1',
      }
    MANIFEST
    end
    let(:pp2) do
      <<-MANIFEST
      File { replace=>true }
      concat { '#{basedir}/foo': }
      concat::fragment { '1':
        target  => '#{basedir}/foo',
        content => 'caller has replace true set run 2',
      }
    MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp1)
      idempotent_apply(pp2)
      expect(file("#{basedir}/foo")).to be_file
      expect(file("#{basedir}/foo").content).not_to match 'caller has replace true set run 1'
      expect(file("#{basedir}/foo").content).to match 'caller has replace true set run 2'
    end
  end
  # should replace its own fragment files when caller has File(replace=>true) set

  describe 'when run should replace its own fragment files even when caller has File { replace=>false } set' do
    let(:pp1) do
      <<-MANIFEST
      File { replace=>false }
      concat { '#{basedir}/foo': }
      concat::fragment { '1':
        target  => '#{basedir}/foo',
        content => 'caller has replace false set run 1',
      }
    MANIFEST
    end
    let(:pp2) do
      <<-MANIFEST
      File { replace=>false }
      concat { '#{basedir}/foo': }
      concat::fragment { '1':
        target  => '#{basedir}/foo',
        content => 'caller has replace false set run 2',
      }
    MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp1)
      idempotent_apply(pp2)
      expect(file("#{basedir}/foo")).to be_file
      expect(file("#{basedir}/foo").content).not_to match 'caller has replace false set run 1'
      expect(file("#{basedir}/foo").content).to match 'caller has replace false set run 2'
    end
  end
  # should replace its own fragment files even when caller has File(replace=>false) set
end
