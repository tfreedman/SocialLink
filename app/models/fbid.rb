class FBID < ActiveRecord::Base
  has_many :to_edges, :foreign_key => 'from', :class_name => 'FBIDEdge'
  has_many :to_fbids, :through => :to_edges

  has_many :from_edges, :foreign_key => 'to', :class_name => 'FBIDEdge'
  has_many :from_fbids, :through => :from_edges

  establish_connection :development

  serialize :reactions
  serialize :author_info
  serialize :payload

  before_save :count_scraped_reactions
  before_save :count_scraped_comments

  attribute :mhtml, :string

  def count_scraped_reactions
    self.reactions_scraped_count = self.edge_reactions.count
  end

  def count_scraped_comments
    self.scraped_comments = self.edge_comments.count
  end

  def authored_by
    x = FBIDEdge.where(from: self.fbid, relationship: ['AUTHORED_BY', 'COMMENT_AUTHORED_BY']).first
    if x
      y = FBID.where(fbid: x.to, fbid_type: 'user').first
      if y
        return y
      else
        return nil
      end
    else
      return nil
    end
  end

  def authored
    return [] if self.fbid_type != 'user'
    x = FBIDEdge.where(from: self.fbid, relationship: ['AUTHORED', 'AUTHORED_COMMENT']).first
    if x
      y = FBID.where(fbid: x.to, fbid_type: 'user').first
      if y
        return y
      else
        return nil
      end
    else
      return nil
    end
  end

  def photos
    if ['user', 'album'].include?(self.fbid_type)
      return []
    end
    #TODO
  end

  def posts
    if ['user'].include?(self.fbid_type)
      return []
    end
    #TODO
  end

  def edge_phototags
    if ['photo'].include?(self.fbid_type)
      return FBIDEdge.where(relationship: 'PHOTO_CONTAINS_PHOTOTAGGEE', from: self.fbid)
    else
      return []
    end
  end

  def edge_comments
    if ['user', nil].include?(self.fbid_type)
      return []
    else
      if ['album', 'post', 'photo'].include?(self.fbid_type)
        edges = FBIDEdge.where(relationship: 'POST_CONTAINS_COMMENT', from: self.fbid)
      elsif ['comment'].include?(self.fbid_type)
        edges = FBIDEdge.where(relationship: 'COMMENT_CONTAINS_REPLY', from: self.fbid)
      end
      return edges
    end
  end

  def edge_reactions
    if ['user'].include?(self.fbid_type)
      return []
    else
      user_relationship_terms = [
        'REACTED_BY_LIKE_TO',
        'REACTED_BY_LOVE_TO',
        'REACTED_BY_HAHA_TO',
        'REACTED_BY_WOW_TO',
        'REACTED_BY_SORRY_TO',
        'REACTED_BY_ANGER_TO',
        'REACTED_BY_THANKFUL_TO',
        'REACTED_BY_PRIDE_TO',
        'REACTED_BY_YAY_TO',
        'REACTED_BY_PLANE_TO',
        'REACTED_BY_CARE_TO'
     ]
      edges = FBIDEdge.where(relationship: user_relationship_terms, to: self.fbid)
      return edges
    end
  end
end
