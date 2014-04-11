class AddWindowToAttributeValueSimilarPatterns < ActiveRecord::Migration
  def change
    add_column :attribute_value_similar_patterns, :window_pre, :text
    add_column :attribute_value_similar_patterns, :window_post, :text
  end
end
