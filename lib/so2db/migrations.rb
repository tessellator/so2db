require 'active_record'
require 'so2db/extensions'
require 'foreigner'


module SO2DB

  module FKHelper

    def add_fk(from_table, to_table, options={})
      begin
        AddForeignKeyMigration.new(from_table, to_table, options).up
      rescue
        s = "Error creating foreign key from #{from_table} to #{to_table}"
        s << " on column #{options[:column]}" if options.has_key? :column
        puts s
      end
    end

  end

  class AddForeignKeyMigration < ActiveRecord::Migration

    def initialize(from_table, to_table, options)
      @from_table = from_table
      @to_table = to_table
      @options = options
    end

    def up
      add_foreign_key(@from_table, @to_table, @options)
    end

  end

  class CreateBasicTables < ActiveRecord::Migration

    def up
      create_table :badges do |t|
        t.integer :user_id
        t.string :name, :limit => 50
        t.timestamp :date
      end

      create_table :comments do |t|
        t.integer :post_id
        t.integer :score
        t.text :text
        t.timestamp :creation_date
        t.string :user_display_name, :limit => 30
        t.integer :user_id
      end

      create_table :posts do |t|
        t.integer :post_type_id
        t.integer :parent_id
        t.integer :accepted_answer_id
        t.timestamp :creation_date
        t.integer :score
        t.integer :view_count
        t.text :body
        t.integer :owner_user_id
        t.text :owner_display_name
        t.integer :last_editor_user_id
        t.string :last_editor_display_name, :limit => 40
        t.timestamp :last_edit_date
        t.timestamp :last_activity_date
        t.timestamp :community_owned_date
        t.timestamp :closed_date
        t.text :title
        t.string :tags, :limit => 150
        t.integer :answer_count
        t.integer :comment_count
        t.integer :favorite_count
      end

      create_table :post_links do |t|
        t.timestamp :creation_date
        t.integer :post_id
        t.integer :related_post_id
        t.integer :link_type_id
      end

      create_table :post_history do |t|
        t.integer :post_history_type_id
        t.integer :post_id
        t.uuid :revision_guid
        t.timestamp :creation_date
        t.integer :user_id
        t.string :user_display_name, :limit => 40
        t.text :comment
        t.text :text
        t.integer :close_reason_id
      end

      create_table :users do |t|
        t.integer :reputation
        t.timestamp :creation_date
        t.text :display_name
        t.string :email_hash, :limit => 32
        t.timestamp :last_access_date
        t.string :website_url, :limit => 300
        t.string :location, :limit => 200
        t.integer :age
        t.text :about_me
        t.integer :views
        t.integer :up_votes
        t.integer :down_votes
      end

      create_table :votes do |t|
        t.integer :post_id
        t.integer :vote_type_id
        t.timestamp :creation_date
        t.integer :user_id
        t.integer :bounty_amount
      end

    end

    def down
      [:votes, :badges, :comments, :post_history, :post_links, :posts, :users].each do |t|
        drop_table t
      end
    end

  end

  class CreateRelationships
    include FKHelper

    def up
      add_fk(:badges, :users)
      add_fk(:comments, :posts)
      add_fk(:comments, :users)
      add_fk(:posts, :posts, column: 'parent_id')

      # The following relationship is currently suspect, see
      # http://meta.stackoverflow.com/questions/131975/what-are-the-posttypeids-in-the-2011-12-data-dump
      add_fk(:posts, :posts, column: 'accepted_answer_id')

      add_fk(:post_links, :posts)
      add_fk(:post_links, :posts, column: 'related_post_id')
      
      add_fk(:posts, :users, column: 'owner_user_id')
      add_fk(:posts, :users, column: 'last_editor_user_id')
      add_fk(:post_history, :posts)
      add_fk(:post_history, :users)

      # In my experience, the following is also suspect
      add_fk(:votes, :posts)
      
      add_fk(:votes, :users)
    end

  end

  class CreateOptionals < ActiveRecord::Migration

    def up
      create_post_types
      create_post_history_types
      create_close_reasons
      create_vote_types
      create_post_link_types
    end

    def create_post_types
      create_table :post_types do |t|
        t.string :type_name, :limit => 24
      end

      { 1 => "Question", 
        2 => "Answer",
        3 => "Wiki",
        4 => "TagWikiExcerpt",
        5 => "TagWiki",
        6 => "ModeratorNomination",
        7 => "WikiPlaceholder",
        8 => "PrivilegeWiki"
      }.each do |k,v|
        p = Models::PostType.new
        p.id = k
        p.type_name = v
        p.save
      end
    end

    def create_post_history_types
      create_table :post_history_types do |t|
        t.string :name, :limit => 50
      end

      { 1  => "Initial Title", 
        2  => "Initial Body", 
        3  => "Initial Tags", 
        4  => "Edit Title", 
        5  => "Edit Body", 
        6  => "Edit Tags", 
        7  => "Rollback Title", 
        8  => "Rollback Body", 
        9  => "Rollback Tags", 
        10 => "Post Closed", 
        11 => "Post Reopened", 
        12 => "Post Deleted", 
        13 => "Post Undeleted", 
        14 => "Post Locked", 
        15 => "Post Unlocked", 
        16 => "Community Owned", 
        17 => "Post Migrated", 
        18 => "Question Merged", 
        19 => "Question Protected", 
        20 => "Question Unprotected", 
        22 => "Question Unmerged", 
        24 => "Suggested Edit Applied", 
        25 => "Post Tweeted", 
        31 => "Discussion moved to chat", 
        33 => "Post Notice Added", 
        34 => "Post Notice Removed", 
        35 => "Post Migrated Away", 
        36 => "Post Migrated Here", 
        37 => "Post Merge Source", 
        38 => "Post Merge Destination" 
      }.each do |k,v|
        p = Models::PostHistoryType.new
        p.id = k
        p.name = v
        p.save
      end
    end

    def create_close_reasons
      create_table :close_reasons do |t|
        t.string :name, :limit => 50
      end

      { 1 => "Exact duplicate",
        2 => "off-topic",
        3 => "subjective",
        4 => "not a real question",
        7 => "too localized",
        10 => "General reference",
        20 => "Noise or pointless"
      }.each do |k,v|
        c = Models::CloseReason.new
        c.id = k
        c.name = v
        c.save
      end
    end

    def create_vote_types
      create_table :vote_types do |t|
        t.string :name, :limit => 50
      end

      { 1 => "AcceptedByOriginator",
        2 =>"UpMod",
        3 => "DownMod",
        4 =>"Offensive",
        5 =>"Favorite",
        6 =>"Close",
        7 =>"Reopen",
        8 =>"BountyStart",
        9 =>"BountyClose",
        10 =>"Deletion",
        11 =>"Undeletion",
        12 =>"Spam",
        15 =>"ModeratorReview",
        16 =>"ApproveEditSuggestion"
      }.each do |k,v|
        vt = Models::VoteType.new
        vt.id = k
        vt.name = v
        vt.save
      end
    end

    def create_post_link_types
      create_table :post_link_types do |t|
        t.string :name, :limit => 50
      end

      { 1 => "Linked",
        3 => "Duplicate"
      }.each do |k,v|
        lt = Models::PostLinkType.new
        lt.id = k
        lt.name = v
        lt.save
      end
    end

  end

  class CreateOptionalRelationships < ActiveRecord::Migration
    include FKHelper

    def up
      add_fk(:posts, :post_types)
      add_fk(:post_history, :post_history_types)
      add_fk(:post_history, :close_reasons)
      add_fk(:votes, :vote_types)
      add_fk(:post_links, :post_link_types, column: 'link_type_id')
    end
  end

end
