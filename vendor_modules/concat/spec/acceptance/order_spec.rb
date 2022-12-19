# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'concat order' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'sortby alpha' do
    let(:pp) do
      <<-MANIFEST
      concat { '#{basedir}/foo':
        order => 'alpha'
      }
      concat::fragment { '1':
        target  => '#{basedir}/foo',
        content => 'string1',
        order   => '1',
      }
      concat::fragment { '2':
        target  => '#{basedir}/foo',
        content => 'string2',
        order   => '2',
      }
      concat::fragment { '10':
        target  => '#{basedir}/foo',
        content => 'string10',
      }
      MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp)
      expect(file("#{basedir}/foo")).to be_file
      expect(file("#{basedir}/foo").content).to match %r{string1string10string2}
    end
  end

  describe 'sortby numeric' do
    let(:pp) do
      <<-MANIFEST
      concat { '#{basedir}/foo':
        order => 'numeric'
      }
      concat::fragment { '1':
        target  => '#{basedir}/foo',
        content => 'string1',
        order   => '1',
      }
      concat::fragment { '2':
        target  => '#{basedir}/foo',
        content => 'string2',
        order   => '2',
      }
      concat::fragment { '10':
        target  => '#{basedir}/foo',
        content => 'string10',
      }
      MANIFEST
    end

    it 'applies the manifest twice with no stderr' do
      idempotent_apply(pp)
      expect(file("#{basedir}/foo")).to be_file
      expect(file("#{basedir}/foo").content).to match %r{string1string2string10}
    end
  end
end
