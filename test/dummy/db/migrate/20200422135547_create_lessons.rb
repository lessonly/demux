class CreateLessons < ActiveRecord::Migration[5.1]
  def change
    create_table :lessons do |t|
      t.string :name
      t.boolean :public
      t.integer :company_id

      t.timestamps
    end
  end
end
