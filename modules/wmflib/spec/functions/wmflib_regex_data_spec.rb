# the main puppet class has issues with the double_instance function
# for now just run this manually with
# bundle exec rspec --format documentation spec/functions/wmflib_regex_data_spec.rb
unless defined?(Puppet)
  class FakeFunction
    def self.dispatch(_name); end
  end

  module Puppet
    module Functions
      def self.create_function(_name, &block)
        FakeFunction.class_eval(&block)
      end
    end
    def self.debug(_msg); end
  end

  require 'puppet/functions/wmflib/regex_data'

  describe FakeFunction do
    include RSpec::Mocks::ExampleMethods

    let(:function) { described_class.new }
    before(:each) do
      @context = instance_double("Puppet::LookupContext")
      allow(@context).to receive(:cache_has_key)
      allow(@context).to receive(:explain)
      allow(@context).to receive(:interpolate) do |val|
        val
      end
      allow(@context).to receive(:not_found)
      allow(@context).to receive(:cache).with('key', 'value').and_return('value')
      allow(File).to receive(:exists?).and_return(true)
    end

    describe "#regex_data" do
      let(:options) do
        {
          'path' => 'regex.yaml',
          'node' => 'node.example.org',
        }
      end

      context "Should run" do
        let(:data) do
          {
            'label' => {
              '__regex' => /node\.example\.org/,
              'key' => 'value'
            }
          }
        end

        it "should run" do
          allow(@context).to receive(:cached_file_data).with('regex.yaml').and_return(data)
          expect(function.regex_data('key', options, @context)).to eq('value')
        end
      end
    end
  end
end
