module Refinery
  module Snippets
    class Snippet < Refinery::Core::BaseModel
      self.table_name = 'refinery_snippets'


      validates :title, :presence => true, :uniqueness => true

      TEMPLATES_DIR = "app/views/shared/snippets"

      acts_as_indexed :fields => [:title, :body]

      translates :body

      has_many :snippet_page_parts, :dependent => :destroy, :class_name => "Refinery::Snippets::SnippetPagePart"
      has_many :page_parts, :through => :snippet_page_parts


      scope :for_page, -> (page){
        raise RuntimeError.new("Couldn't find Snippet for a nil Page") if page.blank?
        joins(:page_parts => :page).where(:refinery_pages => {:id => page.id})
      }

      scope :before, -> {where(:snippets_page_parts => {:before_body => true})}
      scope :after, -> {where(:snippets_page_parts => {:before_body => false})}

      # rejects any snippet that has not been translated to the current
      # locale.
      scope :translated, ->() {
        pages = Arel::Table.new(Refinery::Snippets::Snippet.table_name)
        translations = Arel::Table.new(Refinery::Snippets::Snippet.translations_table_name)

        includes(:translations).where(
            translations[:locale].eq(Globalize.locale)).where(pages[:id].eq(translations[:snippet_id]))
      }

      def pages
        Refinery::Page.for_snippet(self)
      end

      def before?(part)
        part.snippets.before.include? self
      end

      def after?(part)
        part.snippets.after.include? self
      end

      def template_filename
        filename = self.title.strip.gsub(/[^A-Za-z0-9]/,'_').squeeze('_').downcase
        filename = "_#{filename}" unless filename.start_with?('_')
        "#{filename}.html.erb"
      end

      def template_path
        File.join(TEMPLATES_DIR, template_filename)
      end

      def template?
        File.file? template_path
      end

    end
  end
end
