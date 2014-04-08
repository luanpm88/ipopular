class Attribute < ActiveRecord::Base
  validates :name, presence: true
  
  belongs_to :infobox_template  
  has_many :attribute_values
  has_many :attribute_value_similar_patterns
end
