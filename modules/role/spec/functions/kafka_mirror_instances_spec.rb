require 'spec_helper'

describe "kafka_mirror_instances" do
    it "should exist" do
        expect(Puppet::Parser::Functions.function("kafka_mirror_instances")).to eq "function_kafka_mirror_instances"
    end

    it "should raise an ArgumentError if there are anything but 2 arguments" do
        expect { scope.function_kafka_mirror_instances([]) }.to raise_error(ArgumentError)
        expect { scope.function_kafka_mirror_instances([1]) }.to raise_error(ArgumentError)
        expect { scope.function_kafka_mirror_instances([1,2,3,4]) }.to raise_error(ArgumentError)
    end

    it "should raise a ParseError if the first argument is not a Hash" do
        expect { scope.function_kafka_mirror_instances([1, ['a', 'b']]) }.to raise_error(Puppet::ParseError)
    end

    it "should raise a ParseError if the second argument is not a string or a 1 or 2 element Array" do
        expect { scope.function_kafka_mirror_instances([{}, 1]) }.to raise_error(Puppet::ParseError)
        expect { scope.function_kafka_mirror_instances([{}, []]) }.to raise_error(Puppet::ParseError)
        expect { scope.function_kafka_mirror_instances([{}, [1,2,3]]) }.to raise_error(Puppet::ParseError)
    end

    it "should return production main single instance mirror config" do

        # should print kafka_clusters from common.yaml
        p('clusters:', scope.function_hiera(['kafka_clusters', 'NOPE']))

        expected_mirror_instances = {
            'main-eqiad_to_main-codfw' => {
                'source_zookeeper_url' => 'zk1.eqiad.wmnet,zk2.eqiad.wmnet/kafka/main-eqiad',
                'destination_brokers'  => 'kafka2001.codfw.wmnet:9092,kafka2002.codfw.wmnet:9092',
                'jmx_port'             => 9951
            }
        }


        expect(
            scope.function_kafka_mirror_instances([
                { 'eqiad' => ['main'] },
                ['main', 'codfw'],
            ])
        ).to eq(expected_mirror_instances)
    end
end
