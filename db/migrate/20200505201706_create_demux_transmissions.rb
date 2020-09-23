class CreateDemuxTransmissions < ActiveRecord::Migration[5.2]
  def change
    create_table :demux_transmissions do |t|
      t.string :signal_class
      t.string :action
      t.integer :object_id
      t.integer :app_id
      t.integer :account_id
      t.string :account_type
      t.integer :status, default: 0
      t.string :response_code
      t.jsonb :response_headers
      t.text :response_body
      t.jsonb :context
      t.jsonb :request_headers
      t.text :request_body
      t.string :request_url
      t.string :uniqueness_hash

      t.timestamps
    end
    add_index :demux_transmissions, :app_id
    add_index :demux_transmissions, [:uniqueness_hash, :app_id], unique: true, where: "status = 0"
  end
end
