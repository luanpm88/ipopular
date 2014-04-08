class AddStatusToAttributes < ActiveRecord::Migration
  def change
    add_column :attributes, :status, :integer
  end
end
