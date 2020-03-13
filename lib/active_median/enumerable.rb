module Enumerable
  unless method_defined?(:median)
    def median(*args, &block)
      if !block && respond_to?(:scoping)
        scoping { @klass.median(*args) }
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
        scoping { @klass.percentile(*args) }
      elsif !block && respond_to?(:with_scope)
        with_scope(self) { klass.percentile(*args) }
      else
        raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 1)" if args.size != 1

        percentile = args[0].to_f
        raise ArgumentError, "percentile is not between 0 and 1" if percentile < 0 || percentile > 1

        # uses C=1 variant, like percentile_cont
        # https://en.wikipedia.org/wiki/Percentile#The_linear_interpolation_between_closest_ranks_method
        sorted = map(&block).sort
        x = percentile * (sorted.size - 1)
        r = x % 1
        i = x.floor
        if i == sorted.size - 1
          sorted[-1]
        else
          sorted[i] + r * (sorted[i + 1] - sorted[i])
        end
      end
    end
  end
end
