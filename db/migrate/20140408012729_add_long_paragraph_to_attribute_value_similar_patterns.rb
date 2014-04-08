class AddLongParagraphToAttributeValueSimilarPatterns < ActiveRecord::Migration
  def change
    add_column :attribute_value_similar_patterns, :long_paragraph, :integer
  end
end
