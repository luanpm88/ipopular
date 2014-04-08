class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.text :title
      t.text :content
      t.text :content_html
      t.text :content_plain
      t.integer :infobox_template_id
      t.integer :for_test

      t.timestamps
    end
  end
end
