class AttributeValueSimilarPattern < ActiveRecord::Base
  belongs_to :attribute_value
  belongs_to :article
  belongs_to :attribute
  belongs_to :infobox_template
end
