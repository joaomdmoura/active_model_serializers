require 'active_model/serializer/adapter/fragment_cache'

module ActiveModel
  class Serializer
    class Adapter
      extend ActiveSupport::Autoload
      autoload :Json
      autoload :Null
      autoload :JsonApi

      attr_reader :serializer

      def initialize(serializer, options = {})
        @serializer = serializer
        @options = options
      end

      def serializable_hash(options = {})
        raise NotImplementedError, 'This is an abstract method. Should be implemented at the concrete adapter.'
      end

      def as_json(options = {})
        hash = serializable_hash(options)
        include_meta(hash)
      end

      def self.create(resource, options = {})
        override = options.delete(:adapter)
        klass = override ? adapter_class(override) : ActiveModel::Serializer.adapter
        klass.new(resource, options)
      end

      def self.adapter_class(adapter)
        "ActiveModel::Serializer::Adapter::#{adapter.to_s.classify}".safe_constantize
      end

      def fragment_cache(*args)
        raise NotImplementedError, 'This is an abstract method. Should be implemented at the concrete adapter.'
      end

      private

      def cache_check(serializer)
        @serializer = serializer
        @klass      = serializer.class
        if is_cached?
          @klass._cache.fetch(cache_key, @klass._cache_options) do
            yield
          end
        elsif is_fragment_cached?
          FragmentCache.new(self, @serializer, @options, @root).fetch
        else
          yield
        end
      end

      def is_cached?
        @klass._cache && !@klass._cache_only && !@klass._cache_except
      end

      def is_fragment_cached?
        @klass._cache_only && !@klass._cache_except || !@klass._cache_only && @klass._cache_except
      end

      def cache_key
        (@klass._cache_key) ? "#{@klass._cache_key}/#{@serializer.object.id}-#{@serializer.object.updated_at}" : @serializer.object.cache_key
      end

      def meta
        serializer.meta if serializer.respond_to?(:meta)
      end

      def meta_key
        serializer.meta_key || "meta"
      end

      def root
        serializer.json_key
      end

      def include_meta(json)
        json[meta_key] = meta if meta && root
        json
      end
    end
  end
end
