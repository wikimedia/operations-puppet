# the main puppet class has issues with the double_instance function
# for now just run this manually with
# bundle exec rspec --format documentation spec/functions/wmflib_expand_path_spec.rb
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
  end

  require 'puppet/functions/wmflib/expand_path'

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
      allow(File).to receive(:exists?).and_return(true)
    end

    describe "#expand_path" do
        let(:options) { {'path' => '/path'} }

        context "Should run" do
            it "should run" do
            allow(@context).to receive(:cached_file_data).with('/path.yaml').and_return(
              {'key' => 'value'}
            )
            allow(@context).to receive(:cache).with('key', 'value').and_return('value')
            expect(function.expand_path('key', options, @context)).to eq('value')
          end
            it "should expand path" do
              allow(@context).to receive(:cached_file_data).with('/path/foobar.yaml').and_return(
                {'foobar::key' => 'value'}
              )
              allow(@context).to receive(:cache).with('foobar::key', 'value').and_return('value')
              expect(function.expand_path('foobar::key', options, @context)).to eq('value')
            end
        end
    end
  end
end
