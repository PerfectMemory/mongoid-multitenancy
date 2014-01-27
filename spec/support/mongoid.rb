module Mongoid
  module Matchers
    class HaveIndexForMatcher
      def matches?(klass)
        @klass  = klass.is_a?(Class) ? klass : klass.class
        @errors = []

        if Mongoid::VERSION.to_i < 4
          index_options = @klass.index_options
        else
          index_options = Hash[@klass.index_specifications.map{|i| [i.key, i.options]}]
        end

        unless index_options[@index_fields]
          @errors.push "no index for #{@index_fields}"
        else
          if !@options.nil? && !@options.empty?
            @options.each do |option, option_value|
              if index_options[@index_fields][option] != option_value
                @errors.push "index for #{@index_fields.inspect} with options of #{index_options[@index_fields].inspect}"
              end
            end
          end
        end

        @errors.empty?
      end
    end
  end
end