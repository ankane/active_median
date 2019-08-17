Mongoid.logger = $logger
Mongo::Logger.logger = $logger if defined?(Mongo::Logger)

Mongoid.configure do |config|
  config.connect_to "active_median_test"
end

class User
  include Mongoid::Document

  field :visits_count, type: Integer
  field :latitude, type: Float
  field :rating, type: Float
  field :name, type: String
  field :created_at, type: Time

  has_many :posts
end

class Post
  include Mongoid::Document

  belongs_to :user
  field :comments_count, type: Integer
end
