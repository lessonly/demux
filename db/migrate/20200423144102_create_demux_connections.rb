class CreateDemuxConnections < ActiveRecord::Migration[5.1]
  def change
    create_table :demux_connections do |t|
      t.integer :account_id
      t.string :account_type
      t.integer :app_id
      t.text :signals, array:true, default: []

      t.timestamps
    end
    add_index :demux_connections, :signals, using: "gin"
    add_index :demux_connections, [:account_id, :account_type]
    add_index :demux_connections, :app_id
  end
end
