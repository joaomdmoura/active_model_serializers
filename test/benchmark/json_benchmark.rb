# encoding: utf-8
require 'test_helper'
require 'benchmark_helper'
require 'ruby-prof'
require 'rugged'
require 'pry'

module ActionController
  module Serialization
    class ImplicitSerializerTest < ActionController::TestCase
      class MyController < ActionController::Base
        def render_using_implicit_serializer
          @profile = Profile.new({ name: 'Name 1', description: 'Description 1', comments: 'Comments 1' })
          render json: @profile
        end
      end

      tests MyController

      # We just have Null for now, this will change
      def test_render_using_implicit_serializer
        result = RubyProf.profile do
          get :render_using_implicit_serializer
        end

        repo = Rugged::Repository.new('.')
        ref  = repo.head

        actual_commit = ref.target.oid
        last_commit   = ref.target.parents.last.oid
        binding.pry

        # printer = RubyProf::FlatPrinter.new(result)
        # benchmark = JSON.parse(File.read('benchmark.json'))
        # benchmark["results"]["#{ref.target_id}"] = "\"#{__method__.to_s}\": #{result.threads.first.total_time}"

        # open('benchmark.json', 'w') do |f|
        #   f << benchmark.to_json
        # end
      end
    end
  end
end
