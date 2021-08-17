module ActiveMedian
  class SQLiteHandler
    def self.arity
      2
    end

    def self.name
      "percentile"
    end

    def initialize
      @values = []
      @percentile = nil
    end

    # skip checks for
    # 1. percentile between 0 and 100
    # 2. percentile same for all rows
    # since input is already checked
    def step(ctx, value, percentile)
      return if value.nil?
      raise ActiveRecord::StatementInvalid, "1st argument to percentile() is not numeric" unless value.is_a?(Numeric)
      @percentile ||= percentile
      @values << value
    end

    def finalize(ctx)
      if @values.any?
        ctx.result = @values.percentile(@percentile / 100.0)
      end
    end
  end
end
