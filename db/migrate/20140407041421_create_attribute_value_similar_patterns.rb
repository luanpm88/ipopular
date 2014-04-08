class CreateAttributeValueSimilarPatterns < ActiveRecord::Migration
  def change
    create_table :attribute_value_similar_patterns do |t|
      t.integer :attribute_value_id
      t.text :value
      t.integer :paragraph
      t.integer :sentence
      t.integer :word

      t.timestamps
    end
  end
end
