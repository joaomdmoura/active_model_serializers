module ActiveModel
  class Serializer
    class ArraySerializer
      include Enumerable
      delegate :each, to: :@objects

      attr_reader :meta, :meta_key

      def initialize(objects, options = {})
        options.merge!(root: nil)

        puts "" if $debug
        @objects = objects.map do |object|

          puts "serializer: #{ActiveModel::Serializer.serializer_for(object)}" if $debug
          puts "objects: #{object.inspect}" if $debug
          ActiveModel::Serializer.serializer_for(object)
          serializer_class = options.fetch(
            :serializer,
            ActiveModel::Serializer.serializer_for(object)
          )
          serializer_class.new(object, options)
        end
        @meta     = options[:meta]
        @meta_key = options[:meta_key]
      end

      def json_key
        @objects.first.json_key if @objects.first
      end

      def root=(root)
        @objects.first.root = root if @objects.first
      end
    end
  end
end
