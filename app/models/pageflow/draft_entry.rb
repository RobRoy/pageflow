module Pageflow
  class DraftEntry
    include ActiveModel::Conversion

    attr_reader :entry, :draft

    delegate(:id,
             :edit_lock, :account, :theme, :slug,
             :published_until, :published?,
             :to_model, :to_key, :persisted?, :to_json,
             :to => :entry)

    delegate(:title, :summary, :credits, :manual_start,
             :chapters, :pages,
             :image_files, :video_files, :audio_files,
             :to => :draft)

    def initialize(entry, draft = nil)
      @entry = entry
      @draft = draft || entry.draft
    end

    def create_file(model, attributes)
      file = model.create(attributes) do |f|
        f.entry = entry
      end

      usage = @draft.file_usages.create(:file => file)
      file.usage_id = usage.id

      file
    end

    def remove_file(file)
      collection_containing(file).destroy(file)
      file.destroy if file.usages.empty?
    end

    def add_file(file)
      draft.file_usages.create!(:file => file)
    end

    def save!
      draft.save!
    end

    def update_meta_data!(attributes)
      draft.update_attributes!(attributes)
    end

    def self.find(id)
      new(Entry.find(id))
    end

    def self.for_file_usage(usage)
      new(usage.revision.entry)
    end

    def self.accessible_by(ability, action)
      Entry.accessible_by(ability, action).map do |entry|
        DraftEntry.new(entry)
      end
    end

    private

    def collection_containing(file)
      collection_for(file.class.name)
    end

    def collection_for(model_name)
      draft.send(model_name.to_s.underscore.split('/').last.pluralize)
    end
  end
end
