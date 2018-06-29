# Model.has_custom_association association_name, preloader: ->(models) { preload and returns hash with key=model_id }
# Model.has_custom_association association_name, preloader: ->(models) { preload and returns custom result } do |result|
#   custom logic to retrieve value for this model(`result[id]` is used when block is not given)
# end

def (ActiveRecord::Base).has_count_of(name)
  has_custom_association "#{name}_count", preloader: ->(records) {
    counts = Hash.new(0)
    records.group_by(&:class).each do |klass, klass_records|
      counts.update klass.where(id: klass_records.map(&:id)).joins(name).group(:id).count
    end
    counts
  }
end

class User < ActiveRecord::Base
  has_many :posts
  has_custom_association :foobar, preloader: ->(users) {
    Post.where(user_id: users.map(&:id)).shuffle.index_by(&:user_id)
  }
  has_custom_association :foobars, preloader: ->(users) {
    posts_by_id = Post.where(user_id: users.map(&:id)).group_by(&:user_id)
    Hash.new{[]}.update posts_by_id
  }
  has_count_of :posts
end

class Post < ActiveRecord::Base
  has_many :comments
  has_count_of :comments
end

class Comment < ActiveRecord::Base; end

p User.preload(foobar: :comments).map { |u| u.foobar&.comments&.map(&:id) }
p User.preload(:posts_count).map { |u| u.posts_count }
p User.preload(foobar: :comments_count).map { |u| u.foobar&.comments_count }
p User.preload(foobars: :comments_count).map { |u| u.foobars.map(&:comments_count) }
