require 'active_record'

module SO2DB::Models

  class Badge < ActiveRecord::Base
    def self.exported_fields
      return [ :id, :user_id, :name, :date ]
    end
  end

  class Comment < ActiveRecord::Base
    def self.exported_fields
      return [ :id, :post_id, :score, :text, :creation_date, :user_id, 
               :user_display_name ]
    end
  end

  class Post < ActiveRecord::Base
    def self.exported_fields
      return [ :id, :post_type_id, :parent_id, :accepted_answer_id, 
               :creation_date, :score, :view_count, :body, :owner_user_id, 
               :last_editor_user_id, :last_editor_display_name, :last_edit_date,
               :last_activity_date, :community_owned_date, :closed_date, :title,
               :tags, :answer_count, :comment_count, :favorite_count, 
               :owner_display_name ]
    end
  end

  class PostLink < ActiveRecord::Base
    def self.exported_fields
      return [ :id, :creation_date, :post_id, :related_post_id, :link_type_id ]
    end
  end

  class PostHistory < ActiveRecord::Base
    self.table_name = "post_history"

    def self.exported_fields
      return [ :id, :post_history_type_id, :post_id, :revision_guid, 
               :creation_date, :user_id, :user_display_name, :comment, :text,
               :close_reason_id ]
    end
  end

  class User < ActiveRecord::Base
    def self.exported_fields
      return [ :id, :reputation, :creation_date, :display_name, :email_hash,
               :last_access_date, :website_url, :location, :age, :about_me, 
               :views, :up_votes, :down_votes ]
    end
  end

  class Vote < ActiveRecord::Base
    def self.exported_fields
      return [ :id, :post_id, :vote_type_id, :creation_date, :user_id, 
               :bounty_amount ]
    end
  end

  class PostType < ActiveRecord::Base
  end

  class PostLinkType < ActiveRecord::Base
  end

  class PostHistoryType < ActiveRecord::Base
  end

  class CloseReason < ActiveRecord::Base
  end

  class VoteType < ActiveRecord::Base
  end

  # Infrastructure.  Do not call this from your code.
  class Lookup

    @@map = { "badges" => :Badge, "comments" => :Comment,
              "posthistory" => :PostHistory, "posts" => :Post,
              "postlinks" => :PostLink, "users" => :User,
              "votes" => :Vote }

    def self.find_class(file_name)
      Object.const_get("SO2DB").const_get("Models")
        .const_get(@@map[file_name.downcase].to_s)
    end

    def self.get_required_attrs(file_name)
      raw = find_class(file_name).send :exported_fields
      return raw.map {|f| f.to_s.camelize.sub(/Guid/, 'GUID')}
    end

  end

end
