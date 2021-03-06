class InfoboxTemplate < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  
  has_many :attributes
  has_many :articles
  has_many :attribute_value_similar_patterns
end
