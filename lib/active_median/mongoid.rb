module ActiveMedian
  module Mongoid
    # https://www.compose.com/articles/mongo-metrics-finding-a-happy-median/
    def median(column)
      relation =
        all
        .group(_id: nil, count: {"$sum" => 1}, values: {"$push" => "$#{column}"})
        .unwind("$values")
        .asc(:values)
        .project(count: {"$subtract" => ["$count", 1]}, values: 1)
        .project(count: 1, values: 1, midpoint: {"$divide" => ["$count", 2]})
        .project(count: 1, values: 1, midpoint: 1, high: {"$ceil" => "$midpoint"}, low: {"$floor" => "$midpoint"})
        .group(_id: nil, values: {"$push" => "$values"}, high: {"$avg" => "$high"}, low: {"$avg" => "$low"})
        .project(beginValue: {"$arrayElemAt" => ["$values", "$high"]}, endValue: {"$arrayElemAt" => ["$values", "$low"]})
        .project(median: {"$avg" => ["$beginValue", "$endValue"]})

      res = collection.aggregate(relation.pipeline).first
      res ? res["median"] : nil
    end
  end
end
