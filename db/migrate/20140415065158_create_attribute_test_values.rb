class CreateAttributeTestValues < ActiveRecord::Migration
  def change
    create_table :attribute_test_values do |t|
      t.integer :article_id
      t.integer :attribute_id
      t.text :value

      t.timestamps
    end
  end
end
