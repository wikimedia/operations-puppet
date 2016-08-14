#! /usr/bin/env ruby -S rspec

require 'spec_helper'
require 'puppetdb/connection'

describe PuppetDB::Connection do
  context "Query parsing" do
    let(:connection) { PuppetDB::Connection.new }
    it "should handle empty queries" do
      connection.parse_query('').should be_nil
    end

    it "should handle double quoted strings" do
      connection.parse_query('foo="bar"').should eq ["in", "name", ["extract", "certname", ["select-facts", ["and", ["=", "name", "foo"], ["=", "value", "bar"]]]]]
    end

    it "should handle single quoted strings" do
      connection.parse_query('foo=\'bar\'').should eq ["in", "name", ["extract", "certname", ["select-facts", ["and", ["=", "name", "foo"], ["=", "value", "bar"]]]]]
    end

    it "should handle precedence" do
      connection.parse_query('foo=1 or bar=2 and baz=3').should eq ["or", ["in", "name", ["extract", "certname", ["select-facts", ["and", ["=", "name", "foo"], ["=", "value", 1]]]]], ["and", ["in", "name", ["extract", "certname", ["select-facts", ["and", ["=", "name", "bar"], ["=", "value", 2]]]]], ["in", "name", ["extract", "certname", ["select-facts", ["and", ["=", "name", "baz"], ["=", "value", 3]]]]]]]
      connection.parse_query('(foo=1 or bar=2) and baz=3').should eq ["and", ["or", ["in", "name", ["extract", "certname", ["select-facts", ["and", ["=", "name", "foo"], ["=", "value", 1]]]]], ["in", "name", ["extract", "certname", ["select-facts", ["and", ["=", "name", "bar"], ["=", "value", 2]]]]]], ["in", "name", ["extract", "certname", ["select-facts", ["and", ["=", "name", "baz"], ["=", "value", 3]]]]]]
    end

    it "should parse resource queries with only type name" do
      connection.parse_query('file').should eq ["in", "name", ["extract", "certname", ["select-resources", ["and", ["=", "exported", false], ["=", "type", "File"]]]]]
    end

    it "should parse resource queries with only title" do
      connection.parse_query('[foo]').should eq ["in", "name", ["extract", "certname", ["select-resources", ["and", ["=", "exported", false], ["=", "title", "foo"]]]]]
    end

    it "should parse resource queries with only parameters" do
      connection.parse_query('{foo=bar}').should eq ["in", "name", ["extract", "certname", ["select-resources", ["and", ["=", "exported", false], ["=", ["parameter", "foo"], "bar"]]]]]
    end

    it "should parse resource queries for exported resources" do
      connection.parse_query('@@file').should eq ["in", "name", ["extract", "certname", ["select-resources", ["and", ["=", "exported", true], ["=", "type", "File"]]]]]
    end

    it "should parse resource queries with type, title and parameters" do
      connection.parse_query('file[foo]{bar=baz}').should eq ["in", "name", ["extract", "certname", ["select-resources", ["and", ["=", "exported", false], ["=", "type", "File"], ["=", "title", "foo"], ["=", ["parameter", "bar"], "baz"]]]]]
    end

    it "should parse resource queries with tags" do
      connection.parse_query('file[foo]{tag=baz}').should eq ["in", "name", ["extract", "certname", ["select-resources", ["and", ["=", "exported", false], ["=", "type", "File"], ["=", "title", "foo"], ["=", "tag", "baz"]]]]]
    end

    it "should handle precedence within resource parameter queries" do
      connection.parse_query('{foo=1 or bar=2 and baz=3}').should eq ["in", "name", ["extract", "certname", ["select-resources", ["and", ["=", "exported", false], ["or", ["=", ["parameter", "foo"], 1], ["and", ["=", ["parameter", "bar"], 2], ["=", ["parameter", "baz"], 3]]]]]]]
      connection.parse_query('{(foo=1 or bar=2) and baz=3}').should eq ["in", "name", ["extract", "certname", ["select-resources", ["and", ["=", "exported", false], ["or", ["=", ["parameter", "foo"], 1], ["=", ["parameter", "bar"], 2]], ["=", ["parameter", "baz"], 3]]]]]
    end

    it "should capitalize class names" do
      connection.parse_query('class[foo::bar]').should eq ["in", "name", ["extract", "certname", ["select-resources", ["and", ["=", "exported", false], ["=", "type", "Class"], ["=", "title", "Foo::Bar"]]]]]
    end

    it "should parse resource queries with regeexp title matching" do
      connection.parse_query('[~foo]').should eq ["in", "name", ["extract", "certname", ["select-resources", ["and", ["=", "exported", false], ["~", "title", "foo"]]]]]
    end

    it "should be able to negate expressions" do
      connection.parse_query('not foo=bar').should eq ["not", ["in", "name", ["extract", "certname", ["select-facts", ["and", ["=", "name", "foo"], ["=", "value", "bar"]]]]]]
    end
  end
end
