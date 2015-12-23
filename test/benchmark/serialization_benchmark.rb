require 'bundler/setup'

require 'rails'
require 'action_controller'
require 'action_controller/test_case'
require 'action_controller/railtie'
require 'active_support/json'
require 'minitest/autorun'
# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class Foo < Rails::Application
  if Rails.version.to_s.start_with? '4'
    config.action_controller.perform_caching = true
    config.active_support.test_order         = :random
    ActionController::Base.cache_store       = :memory_store
    config.eager_load = false
    config.secret_key_base = 'abc123'
  end
end

require "active_model_serializers"

# require 'fixtures/poro'

module TestHelper
  Routes = ActionDispatch::Routing::RouteSet.new
  Routes.draw do
    get ':controller(/:action(/:id))'
    get ':controller(/:action)'
  end

  ActionController::Base.send :include, Routes.url_helpers
end

ActionController::TestCase.class_eval do
  def setup
    @routes = TestHelper::Routes
  end
end

class Model
  def initialize(hash={})
    @attributes = hash
  end

  def cache_key
    "#{self.class.name.downcase}/#{self.id}-#{self.updated_at}"
  end

  def updated_at
    @attributes[:updated_at] ||= DateTime.now.to_time.to_i
  end

  def read_attribute_for_serialization(name)
    if name == :id || name == 'id'
      id
    else
      @attributes[name]
    end
  end

  def id
    @attributes[:id] || @attributes['id'] || object_id
  end

  def to_param
    id
  end

  def method_missing(meth, *args)
    if meth.to_s =~ /^(.*)=$/
      @attributes[$1.to_sym] = args[0]
    elsif @attributes.key?(meth)
      @attributes[meth]
    else
      super
    end
  end
end
AuthorSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id, :name

  has_many :posts, embed: :ids
  has_one :bio
end
BlogSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id, :name
end
CommentSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id, :body

  def custom_options
    options
  end
end
PostSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id, :title, :body

  has_many :comments, serializer: CommentSerializer
  belongs_to :blog, serializer: BlogSerializer
  belongs_to :author, serializer: AuthorSerializer

  def blog
    Blog.new(id: 999, name: "Custom blog")
  end

  def custom_options
    options
  end
end

CachingAuthorSerializer = Class.new(AuthorSerializer) do
  cache key:'writer'
end
CachingCommentSerializer = Class.new(CommentSerializer) do
  cache expires_in: 1.day
end
CachingPostSerializer = Class.new(PostSerializer) do
  cache key:'post', expires_in: 0.1
  belongs_to :blog, serializer: BlogSerializer
  belongs_to :author, serializer: CachingAuthorSerializer
  has_many :comments, serializer: CachingCommentSerializer

end

Comment  = Class.new(Model)
Author   = Class.new(Model)
Post     = Class.new(Model)
Blog     = Class.new(Model)

module ActionController
  module Serialization
    class SerializerTest < ActionController::TestCase
      class PostController < ActionController::Base

        def render_with_cache_enable
          comment = Comment.new({ id: 1, body: 'ZOMG A COMMENT' })
          author  = Author.new(id: 1, name: 'Joao Moura.')
          post    = Post.new({ id: 1, title: 'New Post', blog:nil, body: 'Body', comments: [comment], author: author })

          render json: post
        end

        def render_with_cache_disabled
          comment = Comment.new({ id: 1, body: 'ZOMG A COMMENT' })
          author  = Author.new(id: 1, name: 'Joao Moura.')
          post    = Post.new({ id: 1, title: 'New Post', blog:nil, body: 'Body', comments: [comment], author: author })

          render json: post, serializer: CachingPostSerializer
        end
      end

      tests PostController

      def test_render_benchmark
        ActionController::Base.cache_store.clear
        get :render_with_cache_enable
        get :render_with_cache_disabled

        expected = {
          id: 1,
          title: 'New Post',
          body: 'Body',
          comments: [
            {
              id: 1,
              body: 'ZOMG A COMMENT' }
          ],
          blog: {
            id: 999,
            name: 'Custom blog'
          },
          author: {
            id: 1,
            name: 'Joao Moura.'
          }
        }

        assert_equal 'application/json', @response.content_type
        assert_equal expected.to_json, @response.body

        n = 1_000
        Benchmark.bmbm do |x|
          x.report("cache") do
            ActionController::Base.cache_store.clear
            i = 0
            while i < n
              get :render_with_cache_enable
              i += 1
            end
          end
          x.report("no cache") do
            ActionController::Base.cache_store.clear
            i = 0
            while i < n
              get :render_with_cache_disabled
              i += 1
            end
          end
        end
        assert_equal expected.to_json, @response.body
      end
    end
  end
end
