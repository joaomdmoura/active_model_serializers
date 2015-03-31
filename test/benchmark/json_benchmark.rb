require 'test_helper'
require 'ruby-prof'

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
        printer = RubyProf::FlatPrinter.new(result)
        open('myfile.out', 'w') do |f|
          f.puts result.threads.first.total_time
        end
      end
    end
  end
end
