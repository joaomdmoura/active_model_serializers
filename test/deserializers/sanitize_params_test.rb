require 'test_helper'

module ActiveModel
  class Serializer
    class SanitizeParamsTest < Minitest::Test
      def with_adapter(adapter)
        old_adapter = ActiveModel::Serializer.config.adapter
        ActiveModel::Serializer.config.adapter = adapter
        yield
      ensure
        ActiveModel::Serializer.config.adapter = old_adapter
      end

      def test_sanitize_attributes
        # class PostSerializer < ActiveModelSerializer
        #   attributes :id, :title, :body
        # end


        payload = {
          'data' => {
            'type' => 'posts',
            'attributes' => {
              'title' => 'Title 1',
              'body' => 'Body 1'
            }
          }
        }

        object = with_adapter :json_api do
          PostSerializer.sanitize_params(ActionController::Parameters.new(payload))
        end

        assert_equal(payload['data'], object)
      end

      def test_sanitize_association_to_one
        payload = {
          'data' => {
            'type' => 'posts',
            'relationships' => {
              'author' => {
                'data' => { 'type' => 'authors', 'id' => 1 }
              }
            }
          }
        }

        object = with_adapter :json_api do
          PostSerializer.sanitize_params(ActionController::Parameters.new(payload))
        end

        assert_equal(payload['data'], object)
      end

      def test_sanitize_null_association_to_one
        payload = {
          'data' => {
            'type' => 'posts',
            'relationships' => {
              'author' => {
                'data' => nil
              }
            }
          }
        }

        object = with_adapter :json_api do
          PostSerializer.sanitize_params(ActionController::Parameters.new(payload))
        end

        assert_equal(payload['data'], object)
      end

      def test_sanitize_association_to_many
        payload = {
          'data' => {
            'type' => 'posts',
            'relationships' => {
              'comments' => {
                'data' => [{ 'type' => 'comments', 'id' => 1 },
                           { 'type' => 'comments', 'id' => 2 }]
              }
            }
          }
        }

        object = with_adapter :json_api do
          PostSerializer.sanitize_params(ActionController::Parameters.new(payload))
        end

        assert_equal(payload['data'], object)
      end

      def test_sanitize_empty_association_to_many
        payload = {
          'data' => {
            'type' => 'posts',
            'relationships' => {
              'comments' => {
                'data' => []
              }
            }
          }
        }

        object = with_adapter :json_api do
          PostSerializer.sanitize_params(ActionController::Parameters.new(payload))
        end

        assert_equal(payload['data'], object)
      end
    end
  end
end