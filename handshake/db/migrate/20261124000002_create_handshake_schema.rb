# Every table uses random uuid keys: no counting-up ids anywhere public.
class CreateHandshakeSchema < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    # An anonymous device. We store only a SHA-256 of the cookie token.
    # Reveal details are encrypted and shared one person at a time.
    create_table :participants, id: :uuid do |t|
      t.string :token_digest, null: false, index: { unique: true }
      t.text :first_name
      t.text :photo_data
      t.text :social_handles
      t.text :phone
      t.string :plan, null: false, default: "free"
      t.datetime :age_confirmed_at
      t.datetime :suspended_at
      t.date :last_seen_on
      t.timestamps
    end

    create_table :venues, id: :uuid do |t|
      t.string :name, null: false
      t.string :public_code, null: false, index: { unique: true }
      t.string :dashboard_token_digest, null: false, index: { unique: true }
      t.string :tent_secret, null: false
      t.timestamps
    end

    # Venue and event zones (10-49). Area zones (50-99) are computed, never stored.
    create_table :zones, id: :uuid do |t|
      t.references :venue, type: :uuid, foreign_key: { on_delete: :nullify }
      t.integer :zone_number, null: false, index: { unique: true }
      t.string :label, null: false
      t.integer :neighbor_numbers, array: true, null: false, default: []
      # Opening window in minutes after local midnight (nil = always open).
      # closes before opens means overnight, e.g. a bar open 17:00-02:00.
      t.integer :opens_minute
      t.integer :closes_minute
      # Optional themed window, e.g. "Thursday trivia" (wday 4, 19:00-22:00).
      t.string :theme_label
      t.integer :theme_wday
      t.integer :theme_start_minute
      t.integer :theme_end_minute
      t.timestamps
    end

    # Short-lived codes. Only an HMAC of the code is stored; rows are deleted
    # within about two minutes of expiry or a match.
    create_table :chat_threads, id: :uuid do |t|
      t.datetime :expires_at, null: false, index: true
      t.string :approval_policy, null: false, default: "unanimous"
      t.integer :max_members, null: false, default: 8
      t.integer :last_seq, null: false, default: 0
      # Aggregate-metric helpers, deleted with the chat.
      t.date :last_message_on
      t.integer :message_days, null: false, default: 0
      t.datetime :became_group_at
      t.timestamps
    end

    create_table :handshake_codes, id: :uuid do |t|
      t.references :participant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :chat_thread, type: :uuid, foreign_key: { on_delete: :cascade }
      t.integer :zone_number, null: false
      t.string :digest, null: false
      t.string :kind, null: false, default: "personal"
      t.datetime :expires_at, null: false, index: true
      t.datetime :consumed_at
      t.timestamps
      t.index [ :zone_number, :digest ], unique: true
    end

    # "I entered your code." A connection needs claims in both directions.
    create_table :code_claims, id: :uuid do |t|
      t.references :handshake_code, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :participant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :created_at, null: false
      t.index [ :handshake_code_id, :participant_id ], unique: true
    end

    create_table :memberships, id: :uuid do |t|
      t.references :chat_thread, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :participant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :alias_name, null: false
      t.datetime :joined_at, null: false
      t.datetime :extend_requested_at
      t.string :policy_vote
      t.timestamps
      t.index [ :chat_thread_id, :participant_id ], unique: true
    end

    # Adding or removing a member. Everyone is asked; nobody is added silently.
    create_table :membership_proposals, id: :uuid do |t|
      t.references :chat_thread, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :subject_participant, type: :uuid, null: false, foreign_key: { to_table: :participants, on_delete: :cascade }
      t.references :proposer_membership, type: :uuid, foreign_key: { to_table: :memberships, on_delete: :nullify }
      t.string :kind, null: false, default: "add"
      t.string :via, null: false, default: "add_in"
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false
      t.datetime :decided_at
      t.timestamps
      t.index [ :chat_thread_id, :status ]
    end

    create_table :proposal_votes, id: :uuid do |t|
      t.references :membership_proposal, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :membership, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :decision, null: false
      t.timestamps
      t.index [ :membership_proposal_id, :membership_id ], unique: true
    end

    create_table :messages, id: :uuid do |t|
      t.references :chat_thread, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :membership, type: :uuid, foreign_key: { on_delete: :nullify }
      t.string :author_alias, null: false
      t.string :kind, null: false, default: "text"
      t.text :body, null: false
      t.integer :seq, null: false
      t.datetime :created_at, null: false
      t.index [ :chat_thread_id, :seq ], unique: true
    end

    # Pairwise reveal ladder: what one member offers another. A step shows
    # only when both have offered it.
    create_table :reveal_grants, id: :uuid do |t|
      t.references :chat_thread, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :from_membership, type: :uuid, null: false, foreign_key: { to_table: :memberships, on_delete: :cascade }
      t.references :to_membership, type: :uuid, null: false, foreign_key: { to_table: :memberships, on_delete: :cascade }
      t.integer :level, null: false, default: 0
      t.timestamps
      t.index [ :from_membership_id, :to_membership_id ], unique: true
    end

    # Minimal reports. Evidence only when the reporter chose to attach it.
    create_table :reports, id: :uuid do |t|
      t.uuid :chat_thread_id
      t.references :reporter_participant, type: :uuid, foreign_key: { to_table: :participants, on_delete: :nullify }
      t.references :reported_participant, type: :uuid, foreign_key: { to_table: :participants, on_delete: :nullify }
      t.string :reported_alias
      t.string :reason, null: false
      t.text :note
      t.text :evidence
      t.string :status, null: false, default: "open"
      t.datetime :resolved_at
      t.timestamps
    end

    # Counts only. No identities, no links between people.
    create_table :venue_daily_counts, id: :uuid do |t|
      t.references :venue, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.date :day, null: false
      t.integer :connections, null: false, default: 0
      t.integer :groups, null: false, default: 0
      t.timestamps
      t.index [ :venue_id, :day ], unique: true
    end

    create_table :daily_metrics, id: :uuid do |t|
      t.date :day, null: false
      t.string :key, null: false
      t.integer :count, null: false, default: 0
      t.timestamps
      t.index [ :day, :key ], unique: true
    end
  end
end
