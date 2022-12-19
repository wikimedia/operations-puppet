# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'concat::fragment order' do
  attr_reader :basedir

  before(:all) do
    @basedir = setup_test_directory
  end

  describe 'with reverse order, alphabetical' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/foo':
          order => 'alpha'
        }
        concat::fragment { '1':
          target  => '#{basedir}/foo',
          content => 'string1',
          order   => '15',
        }
        concat::fragment { '2':
          target  => '#{basedir}/foo',
          content => 'string2',
          # default order 10
        }
        concat::fragment { '3':
          target  => '#{basedir}/foo',
          content => 'string3',
          order   => '1',
        }
      MANIFEST
    end

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/foo")).to be_file
      expect(file("#{basedir}/foo").content).to match %r{string3string2string1}
    end
  end

  describe 'with reverse order, numeric' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/foo':
          order => 'numeric'
        }
        concat::fragment { '1':
          target  => '#{basedir}/foo',
          content => 'string1',
          order   => '15',
        }
        concat::fragment { '2':
          target  => '#{basedir}/foo',
          content => 'string2',
          # default order 10
        }
        concat::fragment { '3':
          target  => '#{basedir}/foo',
          content => 'string3',
          order   => '1',
        }
      MANIFEST
    end

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/foo")).to be_file
      expect(file("#{basedir}/foo").content).to match %r{string3string2string1}
    end
  end

  describe 'with normal order' do
    let(:pp) do
      <<-MANIFEST
        concat { '#{basedir}/foo': }
        concat::fragment { '1':
          target  => '#{basedir}/foo',
          content => 'string1',
          order   => '01',
        }
        concat::fragment { '2':
          target  => '#{basedir}/foo',
          content => 'string2',
          order   => '02'
        }
        concat::fragment { '3':
          target  => '#{basedir}/foo',
          content => 'string3',
          order   => '03',
        }
      MANIFEST
    end

    it 'idempotent, file matches' do
      idempotent_apply(pp)
      expect(file("#{basedir}/foo")).to be_file
      expect(file("#{basedir}/foo").content).to match %r{string1string2string3}
    end
  end
end
