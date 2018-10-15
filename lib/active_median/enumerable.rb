module Enumerable
  unless method_defined?(:median)
    def median(*args, &block)
      if respond_to?(:scoping) && !block
        scoping { @klass.median(*args) }
      else
        sorted = map(&block).sort
        len = sorted.length
        (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
      end
    end
  end
end
