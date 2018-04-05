module ActiveRecord
  module Calculations
    def median(*args)
      calculate(:median, *args)
    end
  end
end

module ActiveRecord
  module Querying
    delegate :median, to: (Gem::Version.new(Arel::VERSION) >= Gem::Version.new("4.0.1") ? :all : :scoped)
  end
end

module Arel
  module Nodes
    const_set("Median", Class.new(Function))
  end
end

module Arel
  module Expressions
    def median
      Nodes::Median.new [self], Nodes::SqlLiteral.new("median_id")
    end
  end
end

module Arel
  module Visitors
    class ToSql
      def visit_Arel_Nodes_Median(o, a = nil)
        if Gem::Version.new(Arel::VERSION) >= Gem::Version.new("6.0.0")
          aggregate "MEDIAN", o, a
        elsif a
          "MEDIAN(#{o.distinct ? 'DISTINCT ' : ''}#{o.expressions.map do |x|
            visit x, a
          end.join(', ')})#{o.alias ? " AS #{visit o.alias, a}" : ''}"
        else
          "MEDIAN(#{o.distinct ? 'DISTINCT ' : ''}#{o.expressions.map do |x|
            visit x
          end.join(', ')})#{o.alias ? " AS #{visit o.alias}" : ''}"
        end
      end
    end
  end
end

module Arel
  module Visitors
    class DepthFirst
      alias :visit_Arel_Nodes_Median :function
    end
  end
end

module Arel
  module Visitors
    class Dot
      alias :visit_Arel_Nodes_Median :function
    end
  end
end
