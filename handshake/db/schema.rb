# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_24_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "chat_threads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "expires_at", null: false
    t.string "approval_policy", default: "unanimous", null: false
    t.integer "max_members", default: 8, null: false
    t.integer "last_seq", default: 0, null: false
    t.date "last_message_on"
    t.integer "message_days", default: 0, null: false
    t.datetime "became_group_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "engaged_at"
    t.index ["expires_at"], name: "index_chat_threads_on_expires_at"
  end

  create_table "code_claims", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "handshake_code_id", null: false
    t.uuid "participant_id", null: false
    t.datetime "created_at", null: false
    t.index ["handshake_code_id", "participant_id"], name: "index_code_claims_on_handshake_code_id_and_participant_id", unique: true
    t.index ["handshake_code_id"], name: "index_code_claims_on_handshake_code_id"
    t.index ["participant_id"], name: "index_code_claims_on_participant_id"
  end

  create_table "daily_metrics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "day", null: false
    t.string "key", null: false
    t.integer "count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day", "key"], name: "index_daily_metrics_on_day_and_key", unique: true
  end

  create_table "handshake_codes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_id", null: false
    t.uuid "chat_thread_id"
    t.integer "zone_number", null: false
    t.string "digest", null: false
    t.string "kind", default: "personal", null: false
    t.datetime "expires_at", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_thread_id"], name: "index_handshake_codes_on_chat_thread_id"
    t.index ["expires_at"], name: "index_handshake_codes_on_expires_at"
    t.index ["participant_id"], name: "index_handshake_codes_on_participant_id"
    t.index ["zone_number", "digest"], name: "index_handshake_codes_on_zone_number_and_digest", unique: true
  end

  create_table "membership_proposals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "chat_thread_id", null: false
    t.uuid "subject_participant_id", null: false
    t.uuid "proposer_membership_id"
    t.string "kind", default: "add", null: false
    t.string "via", default: "add_in", null: false
    t.string "status", default: "pending", null: false
    t.datetime "expires_at", null: false
    t.datetime "decided_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_thread_id", "status"], name: "index_membership_proposals_on_chat_thread_id_and_status"
    t.index ["chat_thread_id"], name: "index_membership_proposals_on_chat_thread_id"
    t.index ["proposer_membership_id"], name: "index_membership_proposals_on_proposer_membership_id"
    t.index ["subject_participant_id"], name: "index_membership_proposals_on_subject_participant_id"
  end

  create_table "memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "chat_thread_id", null: false
    t.uuid "participant_id", null: false
    t.string "alias_name", null: false
    t.datetime "joined_at", null: false
    t.datetime "extend_requested_at"
    t.string "policy_vote"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_thread_id", "participant_id"], name: "index_memberships_on_chat_thread_id_and_participant_id", unique: true
    t.index ["chat_thread_id"], name: "index_memberships_on_chat_thread_id"
    t.index ["participant_id"], name: "index_memberships_on_participant_id"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "chat_thread_id", null: false
    t.uuid "membership_id"
    t.string "author_alias", null: false
    t.string "kind", default: "text", null: false
    t.text "body", null: false
    t.integer "seq", null: false
    t.datetime "created_at", null: false
    t.index ["chat_thread_id", "seq"], name: "index_messages_on_chat_thread_id_and_seq", unique: true
    t.index ["chat_thread_id"], name: "index_messages_on_chat_thread_id"
    t.index ["membership_id"], name: "index_messages_on_membership_id"
  end

  create_table "participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "token_digest", null: false
    t.text "first_name"
    t.text "photo_data"
    t.text "social_handles"
    t.text "phone"
    t.string "plan", default: "free", null: false
    t.datetime "age_confirmed_at"
    t.datetime "suspended_at"
    t.date "last_seen_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_participants_on_token_digest", unique: true
  end

  create_table "proposal_votes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "membership_proposal_id", null: false
    t.uuid "membership_id", null: false
    t.string "decision", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["membership_id"], name: "index_proposal_votes_on_membership_id"
    t.index ["membership_proposal_id", "membership_id"], name: "idx_on_membership_proposal_id_membership_id_8632523323", unique: true
    t.index ["membership_proposal_id"], name: "index_proposal_votes_on_membership_proposal_id"
  end

  create_table "reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "chat_thread_id"
    t.uuid "reporter_participant_id"
    t.uuid "reported_participant_id"
    t.string "reported_alias"
    t.string "reason", null: false
    t.text "note"
    t.text "evidence"
    t.string "status", default: "open", null: false
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reported_participant_id"], name: "index_reports_on_reported_participant_id"
    t.index ["reporter_participant_id"], name: "index_reports_on_reporter_participant_id"
  end

  create_table "reveal_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "chat_thread_id", null: false
    t.uuid "from_membership_id", null: false
    t.uuid "to_membership_id", null: false
    t.integer "level", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_thread_id"], name: "index_reveal_grants_on_chat_thread_id"
    t.index ["from_membership_id", "to_membership_id"], name: "index_reveal_grants_on_from_membership_id_and_to_membership_id", unique: true
    t.index ["from_membership_id"], name: "index_reveal_grants_on_from_membership_id"
    t.index ["to_membership_id"], name: "index_reveal_grants_on_to_membership_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "venue_daily_counts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "venue_id", null: false
    t.date "day", null: false
    t.integer "connections", default: 0, null: false
    t.integer "groups", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["venue_id", "day"], name: "index_venue_daily_counts_on_venue_id_and_day", unique: true
    t.index ["venue_id"], name: "index_venue_daily_counts_on_venue_id"
  end

  create_table "venues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "public_code", null: false
    t.string "dashboard_token_digest", null: false
    t.string "tent_secret", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_token_digest"], name: "index_venues_on_dashboard_token_digest", unique: true
    t.index ["public_code"], name: "index_venues_on_public_code", unique: true
  end

  create_table "zones", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "venue_id"
    t.integer "zone_number", null: false
    t.string "label", null: false
    t.integer "neighbor_numbers", default: [], null: false, array: true
    t.integer "opens_minute"
    t.integer "closes_minute"
    t.string "theme_label"
    t.integer "theme_wday"
    t.integer "theme_start_minute"
    t.integer "theme_end_minute"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["venue_id"], name: "index_zones_on_venue_id"
    t.index ["zone_number"], name: "index_zones_on_zone_number", unique: true
  end

  add_foreign_key "code_claims", "handshake_codes", on_delete: :cascade
  add_foreign_key "code_claims", "participants", on_delete: :cascade
  add_foreign_key "handshake_codes", "chat_threads", on_delete: :cascade
  add_foreign_key "handshake_codes", "participants", on_delete: :cascade
  add_foreign_key "membership_proposals", "chat_threads", on_delete: :cascade
  add_foreign_key "membership_proposals", "memberships", column: "proposer_membership_id", on_delete: :nullify
  add_foreign_key "membership_proposals", "participants", column: "subject_participant_id", on_delete: :cascade
  add_foreign_key "memberships", "chat_threads", on_delete: :cascade
  add_foreign_key "memberships", "participants", on_delete: :cascade
  add_foreign_key "messages", "chat_threads", on_delete: :cascade
  add_foreign_key "messages", "memberships", on_delete: :nullify
  add_foreign_key "proposal_votes", "membership_proposals", on_delete: :cascade
  add_foreign_key "proposal_votes", "memberships", on_delete: :cascade
  add_foreign_key "reports", "participants", column: "reported_participant_id", on_delete: :nullify
  add_foreign_key "reports", "participants", column: "reporter_participant_id", on_delete: :nullify
  add_foreign_key "reveal_grants", "chat_threads", on_delete: :cascade
  add_foreign_key "reveal_grants", "memberships", column: "from_membership_id", on_delete: :cascade
  add_foreign_key "reveal_grants", "memberships", column: "to_membership_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "venue_daily_counts", "venues", on_delete: :cascade
  add_foreign_key "zones", "venues", on_delete: :nullify
end
