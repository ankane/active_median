module ActiveMedian
  module Mongoid
    def median(column)
      percentile(column, 0.5)
    end

    # https://www.compose.com/articles/mongo-metrics-finding-a-happy-median/
    def percentile(column, percentile)
      percentile = percentile.to_f
      raise ArgumentError, "percentile is not between 0 and 1" if percentile < 0 || percentile > 1

      relation =
        all
        .where(column => {"$ne" => nil})
        .asc(column)
        .group(_id: nil, values: {"$push" => "$#{column}"}, count: {"$sum" => 1})
        .project(values: 1, count: {"$subtract" => ["$count", 1]})
        .project(values: 1, count: 1, x: {"$multiply" => ["$count", percentile]})
        .project(values: 1, count: 1, r: {"$mod" => ["$x", 1]}, i: {"$floor" => "$x"})
        .project(values: 1, count: 1, r: 1, i: 1, i2: {"$add" => ["$i", 1]})
        .project(values: 1, count: 1, r: 1, i: 1, i2: {"$min" => ["$i2", "$count"]})
        .project(r: 1, beginValue: {"$arrayElemAt" => ["$values", "$i"]}, endValue: {"$arrayElemAt" => ["$values", "$i2"]})
        .project(r: 1, beginValue: 1, result: {"$subtract" => ["$endValue", "$beginValue"]})
        .project(beginValue: 1, result: {"$multiply" => ["$result", "$r"]})
        .project(result: {"$add" => ["$beginValue", "$result"]})

      res = collection.aggregate(relation.pipeline).first
      res ? res["result"] : nil
    end
  end
end
