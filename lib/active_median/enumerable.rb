module Enumerable
  unless method_defined?(:median)
    def median(*args, &block)
      if !block && respond_to?(:scoping)
        scoping { @klass.median(*args) }
      elsif !block && respond_to?(:with_scope)
        with_scope(self) { klass.median(*args) }
      else
        sorted = map(&block).sort
        len = sorted.length
        (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
      end
    end
  end
end
