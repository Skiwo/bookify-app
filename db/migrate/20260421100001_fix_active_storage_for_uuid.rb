class FixActiveStorageForUuid < ActiveRecord::Migration[8.0]
  def up
    drop_table :active_storage_variant_records, if_exists: true
    drop_table :active_storage_attachments, if_exists: true
    drop_table :active_storage_blobs, if_exists: true

    create_table :active_storage_blobs, id: :primary_key do |t|
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum
      t.datetime :created_at,   null: false

      t.index [:key], unique: true
    end

    create_table :active_storage_attachments, id: :primary_key do |t|
      t.string   :name,        null: false
      t.string   :record_type, null: false
      t.uuid     :record_id,   null: false
      t.bigint   :blob_id,     null: false
      t.datetime :created_at,  null: false

      t.index :blob_id
      t.index [:record_type, :record_id, :name, :blob_id],
        name: "index_active_storage_attachments_uniqueness", unique: true
    end

    create_table :active_storage_variant_records, id: :primary_key do |t|
      t.bigint :blob_id,          null: false
      t.string :variation_digest, null: false

      t.index [:blob_id, :variation_digest],
        name: "index_active_storage_variant_records_uniqueness", unique: true
    end

    add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id
    add_foreign_key :active_storage_variant_records, :active_storage_blobs, column: :blob_id
  end
end
