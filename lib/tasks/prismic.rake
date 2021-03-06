namespace :prismic do
  desc 'Migrate all prismic documents to fincap. Example rake prismic:migrate[~/prismic_files]'
  task :migrate, [:dir] => :environment do |t, args|
    documents = Prismic::Document.all(args[:dir])
    converted_documents = documents.map(&:to_cms)
    errors = []
    skipped = []
    passed = []

    converted_documents.map do |converted_document|
      begin
        converted_document.migrate
        print "\e[32m.\e[0m"
        passed << converted_document
      rescue StandardError, NotImplementedError => exception
        if exception.message.include?('uninitialized constant') || exception.message.include?('wrong constant name')
          print "\e[34mS\e[0m"
          skipped << converted_document
        else
          print "\e[31mF\e[0m"
          errors << "Failed migration from document with title: '#{converted_document.formatted_title}' and with type: '#{converted_document.type}' with slug: '#{converted_document.slug}'. Exception: #{exception.message}"
        end
      end
    end

    puts
    puts "#{converted_documents.size} documents. #{passed.size} passed, #{skipped.size} skipped, #{errors.size} errors"

    if errors.present?
      puts
      puts errors
    end
  end

  desc 'Convert into html files'
  task :convert_to_html, [:dir] => :environment do |t, args|
    documents = Prismic::Document.all(args[:dir])
    converted_documents = documents.map(&:to_cms)

    converted_documents.each do |converted_document|
      template = %{
        <html>
          <head><title><%= formatted_title %></title></head>
          <body>
            <% attributes.each do |attribute| %>
              <h2>Attribute "<%= attribute %>"</h2>
              <h3>Value</h3>
              <%= self.send(attribute) %>
            <% end %>
          </body>
        </html>
      }
      view = ERB.new(template)

      File.open("tmp/#{converted_document.filename}.html", 'w') do |f|
        f.puts(view.result(converted_document.get_binding))
      end
    end
  end

  desc 'Show statistics for Prismic pages given a directory. Example: rake prismic:statistics[~/prismic_files]'
  task :statistics, [:dir] => :environment do |t, args|
    Prismic::Statistics.new(args[:dir]).call
  end

  desc 'Show information about each evidence hub field type. Example: rake prismic:fields[~/Downloads/fincap,insight]'
  task :fields, [:dir, :evidence_type] => :environment do |t, args|
    Prismic::Fields.new(args[:dir], args[:evidence_type]).filter.print_table
  end
end

module Prismic
  class Fields
    attr_reader :parser, :evidence_type, :result

    def initialize(dir, evidence_type)
      @parser = Prismic::Parser.new(dir)
      @evidence_type = evidence_type
      @filter = {}
      @example = {}
      @rows = []
    end

    def filter
      documents.each_with_index do |document, index|
        document.to_h.map do |key, value|
          maximum_field_size = [
            value.try(:size),
            @filter[key].try(:size)
          ].compact.max

          field_type = if value == 'Yes' || value == 'No'
                         'Boolean'
                       else
                         value.class
                       end

          @filter[key] = [maximum_field_size, field_type]
        end
      end

      documents.each do |document|
        document.to_h.map do |key, value|
          @example[key] = value
        end
      end

      self
    end

    def documents
      @documents ||= @parser.send(@evidence_type)
    end

    def print_table
      puts "=" * 80
      puts "An example of #{evidence_type}"
      puts "=" * 80

      @example.each do |field, value|
        puts "-" * 80
        puts "Field '#{field}'. Value: '#{value}'"
        puts "-" * 80
      end

      puts

      puts "Number of fields: #{@filter.keys.size}"

      @filter.each do |field, values|
        @rows.push([field, values, nil, nil, nil, nil].flatten)
      end

      puts Terminal::Table.new(
        title: "#{evidence_type} Field Structure",
        headings: ['Field', 'Size', 'Current format', 'CMS Format', 'Mandatory?', 'Needs Migrating?', 'Needs Transforming?' ],
        rows: @rows
      )
    end
  end
end

module Prismic
  class HubImport
    attr_reader :parser

    def initialize(dir)
      @parser = Prismic::Parser.new(dir)
    end

    def call
      @site = Comfy::Cms::Site.first

      ## Create the evidence types as CMS layouts
      parser.evidence_types.compact.uniq.each do |evidence_type|
        @site.layouts.find_or_create_by(
          label: evidence_type.titleize,
          identifier: evidence_type.parameterize
        )
      end

      [parser.evidence_hub_pages.first].each do |evidence_hub_page|
        @site.pages.create do |cms_page|
          cms_page.label = evidence_hub_page.title
          cms_page.slug  = evidence_hub_page.title.parameterize

          cms_page.layout = Comfy::Cms::Layout.find_by(
            identifier: evidence_hub_page.evidence_type.parameterize
          )
          cms_page.blocks = evidence_hub_page.to_h.except(
            :type, :evidence_type, :new, :tag, :lang
          ).map do |key, value|
            Comfy::Cms::Block.new do |cms_block|
              cms_block.identifier = key
              cms_block.content = value
            end
          end
        end
      end
    end
  end
end

module Prismic
  class Parser
    def initialize(dir)
      @files = Dir[File.expand_path("#{dir}/*.json")]
    end

    def evidence_hub_pages
      pages.select { |page| page.type == 'hub-summary' }
    end

    def page_types
      pages.map { |page| page.type }
    end

    def evidence_types
      pages.map { |page| page.evidence_type }
    end

    def insight
      evidence_hub_pages.select { |page| page.evidence_type == 'Insight' }
    end

    def evaluation
      evidence_hub_pages.select { |page| page.evidence_type == 'Evaluation' }
    end

    def review
      evidence_hub_pages.select { |page| page.evidence_type == 'Review' }
    end

    def pages
      @pages ||= @files.map do |file|
        OpenStruct.new(JSON.parse(File.read(file)))
      end
    end
  end
end

module Prismic
  class Statistics
    attr_reader :parser, :report

    def initialize(dir)
      @parser = Prismic::Parser.new(dir)
      @report = { 'types' => {}, 'evidence types' => {} }
    end

    def call
      group(parser.page_types, name: 'types')
      group(parser.evidence_types, name: 'evidence types')

      puts @report
    end

    def group(data, name:)
      data.group_by(&:itself).each { |k, v| @report[name][k] = v.length }
    end
  end
end
