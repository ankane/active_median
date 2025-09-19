module Enumerable
  unless method_defined?(:median)
    def median(*args, &block)
      if !block && respond_to?(:scoping)
        scoping { klass.median(*args) }
      elsif !block && respond_to?(:with_scope)
        with_scope(self) { klass.median(*args) }
      else
        raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 0)" if args.any?
        percentile(0.5, &block)
      end
    end
  end

  unless method_defined?(:percentile)
    def percentile(*args, &block)
      if !block && respond_to?(:scoping)
        scoping { klass.percentile(*args) }
      elsif !block && respond_to?(:with_scope)
        with_scope(self) { klass.percentile(*args) }
      else
        raise ArgumentError, "wrong number of arguments (given #{args.size}, expected at least 1)" if args.empty?

        percentiles = args.map do |percentile|
          Float(percentile, exception: false).tap do |p|
            raise ArgumentError, "invalid percentile" if p.nil?
            raise ArgumentError, "percentile is not between 0 and 1" if p < 0 || p > 1
          end
        end

        # uses C=1 variant, like percentile_cont
        # https://en.wikipedia.org/wiki/Percentile#The_linear_interpolation_between_closest_ranks_method
        sorted = map(&block).sort

        results = percentiles.map do |percentile|
          x = percentile * (sorted.size - 1)
          r = x % 1
          i = x.floor
          if i == sorted.size - 1
            sorted[-1]
          else
            sorted[i] + r * (sorted[i + 1] - sorted[i])
          end
        end

        percentiles.one? ? results.first : results
      end
    end
    alias_method :percentiles, :percentile
  end
end
