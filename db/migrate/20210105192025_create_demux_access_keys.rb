class CreateDemuxAccessKeys < ActiveRecord::Migration[5.2]
  def change
    create_table :demux_access_keys do |t|
      t.text :public_key, null: false
      t.integer :app_id, null: false
      t.string :fingerprint, null: false

      t.timestamps
    end

    add_index :demux_access_keys, :app_id
  end
end
