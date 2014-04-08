class AttributeValue < ActiveRecord::Base
  belongs_to :article
  belongs_to :attribute
  
  has_many :attribute_value_similar_patterns
end
