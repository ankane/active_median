module ActiveMedian
  module Mongoid
    def median(column)
      percentile(column, 0.5)
    end

    # https://www.compose.com/articles/mongo-metrics-finding-a-happy-median/
    def percentile(column, *percentiles)
      raise ArgumentError, "wrong number of arguments (given #{percentiles.size}, expected at least 1)" if percentiles.empty?

      percentiles.map do |percentile|
        Float(percentile, exception: false).tap do |p|
          raise ArgumentError, "invalid percentile" if p.nil?
          raise ArgumentError, "percentile is not between 0 and 1" if p < 0 || p > 1
        end
      end

      # Build aggregation pipeline that calculates all percentiles in one query
      relation = all
        .where(column => {"$ne" => nil})
        .asc(column)
        .group(_id: nil, values: {"$push" => "$#{column}"}, count: {"$sum" => 1})
        .project(values: 1, count: {"$subtract" => ["$count", 1]})

      x = percentiles.map.with_index do |percentile, index|
        ["p#{index}_x", {"$multiply" => ["$count", percentile]}]
      end.to_h
      relation = relation.project(values: 1, count: 1, **x)

      ri = percentiles.flat_map.with_index do |_, index|
        [["p#{index}_r", {"$mod" => ["$p#{index}_x", 1]}], ["p#{index}_i", {"$floor" => "$p#{index}_x"}]]
      end.to_h
      relation = relation.project(values: 1, count: 1, **ri)

      i2 = percentiles.flat_map.with_index do |_, index|
        [["p#{index}_r", 1], ["p#{index}_i", 1], ["p#{index}_i2", {"$add" => ["$p#{index}_i", 1]}]]
      end.to_h
      relation = relation.project(values: 1, count: 1, **i2)

      min_i2 = percentiles.flat_map.with_index do |_, index|
        [["p#{index}_r", 1], ["p#{index}_i", 1], ["p#{index}_i2", {"$min" => ["$p#{index}_i2", "$count"]}]]
      end.to_h
      relation = relation.project(values: 1, **min_i2)

      begin_end = percentiles.flat_map.with_index do |_, index|
        [["p#{index}_r", 1], ["p#{index}_begin", {"$arrayElemAt" => ["$values", "$p#{index}_i"]}], ["p#{index}_end", {"$arrayElemAt" => ["$values", "$p#{index}_i2"]}]]
      end.to_h
      relation = relation.project(begin_end)

      diff = percentiles.flat_map.with_index do |_, index|
        [["p#{index}_r", 1], ["p#{index}_begin", 1], ["p#{index}_diff", {"$subtract" => ["$p#{index}_end", "$p#{index}_begin"]}]]
      end.to_h
      relation = relation.project(diff)

      mult = percentiles.flat_map.with_index do |_, index|
        [["p#{index}_begin", 1], ["p#{index}_mult", {"$multiply" => ["$p#{index}_diff", "$p#{index}_r"]}]]
      end.to_h
      relation = relation.project(mult)

      result = percentiles.map.with_index do |_, index|
        ["p#{index}_result", {"$add" => ["$p#{index}_begin", "$p#{index}_mult"]}]
      end.to_h
      relation = relation.project(result)

      res = collection.aggregate(relation.pipeline).first
      if res
        results = percentiles.each_with_index.map { |_, i| res["p#{i}_result"] }
        percentiles.one? ? results.first : results
      else
        percentiles.one? ? nil : nil
      end
    end
    alias_method :percentiles, :percentile
  end
end
