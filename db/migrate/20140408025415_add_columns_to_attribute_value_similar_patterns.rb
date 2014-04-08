class AddColumnsToAttributeValueSimilarPatterns < ActiveRecord::Migration
  def change
    add_column :attribute_value_similar_patterns, :article_id, :integer
    add_column :attribute_value_similar_patterns, :attribute_id, :integer
  end
end
