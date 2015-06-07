#--
# Copyright (c) 2012 Chad Taylor
#
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights 
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
# SOFTWARE.

require 'active_record'

module SO2DB::Models

  class Badge < ActiveRecord::Base
    def self.exported_fields
      return [ :id, :user_id, :name, :date, :class, :tag_based ]
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
               :views, :up_votes, :down_votes, :account_id ]
    end
  end

  class Vote < ActiveRecord::Base
    def self.exported_fields
      return [ :id, :post_id, :vote_type_id, :creation_date, :user_id, 
               :bounty_amount ]
    end
  end

  class PostLink < ActiveRecord::Base
    def self.exported_fields
      return [ :id, :creation_date, :post_id, :related_post_id, :link_type_id ]
    end
  end

  class Tag < ActiveRecord::Base
    def self.exported_fields
      return [ :id, :tag_name, :count, :excerpt_post_id, :wiki_post_id ]
    end
  end

  class PostType < ActiveRecord::Base
  end

  class PostHistoryType < ActiveRecord::Base
  end

  class CloseReason < ActiveRecord::Base
  end

  class VoteType < ActiveRecord::Base
  end

  # Infrastructure.  Do not call this from your code.
  class Lookup

    @@map = { "Badges" => :Badge, "Comments" => :Comment,
              "PostHistory" => :PostHistory, "Posts" => :Post, "Users" => :User,
              "Votes" => :Vote, "PostLinks" => :PostLink, "Tags" => :Tag }

    def self.find_class(file_name)
      Object.const_get("SO2DB").const_get("Models")
      .const_get(@@map[file_name].to_s)
    end

    def self.get_required_attrs(file_name)
      raw = find_class(file_name).send :exported_fields
      return raw.map {|f| f.to_s.camelize.sub(/Guid/, 'GUID')}
    end
  end
end
