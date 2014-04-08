class AddInfoboxTemplateIdToAttributeValueSimilarPatterns < ActiveRecord::Migration
  def change
    add_column :attribute_value_similar_patterns, :infobox_template_id, :integer
  end
end
