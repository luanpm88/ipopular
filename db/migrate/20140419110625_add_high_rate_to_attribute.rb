class AddHighRateToAttribute < ActiveRecord::Migration
  def change
    add_column :attributes, :high_rate, :integer
  end
end
