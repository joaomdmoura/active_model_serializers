require 'active_model/serializer/adapter/json/fragment_cache'

module ActiveModel
  class Serializer
    class Adapter
      class Json < Adapter
        def serializable_hash(options = nil)
          if serializer.respond_to?(:each)
            @result = serializer.map{|s| FlattenJson.new(s, @options).serializable_hash }
          else
            @hash = {}

            @core = cache_check(serializer) do
              options = {fields: @fieldset && @fieldset.fields_for(serializer)}
              serializer.attributes(options)
            end

            serializer.each_association do |key, association, opts|
              if association.respond_to?(:each)
                array_serializer = association
                @hash[key] = array_serializer.map do |item|
                  cache_check(item) do
                    item.attributes(opts.merge(fields: @fieldset && @fieldset.fields_for(item)))
                  end
                end
              else
                if association && association.object
                  @hash[key] = cache_check(association) do
                    options[:fields] = @fieldset && @fieldset.fields_for(association)
                    association.attributes(options)
                  end
                elsif opts[:virtual_value]
                  @hash[key] = opts[:virtual_value]
                else
                  @hash[key] = nil
                end
              end
            end
            @result = @core.merge @hash
          end

          { root => @result }
        end

        def fragment_cache(cached_hash, non_cached_hash)
          Json::FragmentCache.new().fragment_cache(cached_hash, non_cached_hash)
        end

      end
    end
  end
end
