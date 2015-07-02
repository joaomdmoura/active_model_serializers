require 'test_helper'
require 'generators/serializer/serializer_generator'

class SerializerGeneratorTest < Rails::Generators::TestCase
  destination File.expand_path("../../../tmp/generators", __FILE__)
  setup :prepare_destination

  tests Rails::Generators::SerializerGenerator
  arguments %w(account name:string description:text business:references)

  def test_generates_a_serializer
    run_generator
    assert_file "app/serializers/account_serializer.rb", /class AccountSerialization < ActiveModel::Serializer/
  end

  def test_generates_a_namespaced_serializer
    run_generator ["admin/account"]
    assert_file "app/serializers/admin/account_serializer.rb", /class Admin::AccountSerialization < ActiveModel::Serializer/
  end

  def test_uses_application_serializer_if_one_exists
    Object.const_set(:ApplicationSerializer, Class.new)
    run_generator
    assert_file "app/serializers/account_serializer.rb", /class AccountSerialization < ApplicationSerializer/
  ensure
    Object.send :remove_const, :ApplicationSerializer
  end

  def test_uses_given_parent
    Object.const_set(:ApplicationSerializer, Class.new)
    run_generator ["Account", "--parent=MySerializer"]
    assert_file "app/serializers/account_serializer.rb", /class AccountSerialization < MySerializer/
  ensure
    Object.send :remove_const, :ApplicationSerializer
  end

  def test_generates_attributes_and_associations
    run_generator
    assert_file "app/serializers/account_serializer.rb" do |serializer|
      assert_match(/^  attributes :id, :name, :description$/, serializer)
      assert_match(/^  has_one :business$/, serializer)
      assert_match(/^end\n*\z/, serializer)
    end
  end

  def test_with_no_attributes_does_not_add_extra_space
    run_generator ["account"]
    assert_file "app/serializers/account_serializer.rb" do |content|
      assert_no_match /\n\nend/, content
    end
  end
end
