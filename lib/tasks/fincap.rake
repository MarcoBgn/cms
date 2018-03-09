namespace :fincap do
  desc 'Setup fincap data'
  task setup: :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)

    Comfy::Cms::User.create_with(password: 'password', role: 'admin').find_or_create_by!(email: 'user@test.com')

    english_site = Comfy::Cms::Site.find_or_create_by(
      label: 'en',
      identifier: 'money-advice-service-en',
      hostname: ENV['HOSTNAME'] || 'localhost:3000',
      path: 'en',
      locale: 'en',
      is_mirrored: true
    )

    %w(insight).each do |layout|
      english_site.layouts.find_or_create_by(
        identifier: layout,
        label: layout.titleize,
        content:  <<-CONTENT
          {{ cms:page:content:rich_text }}
          {{ cms:page:overview }}
          {{ cms:page:countries }}
          {{ cms:page:links_to_research }}
          {{ cms:page:contact_details }}
          {{ cms:page:year_of_publication }}
          {{ cms:page:topics:collection_check_boxes/Saving, Pensions and Retirement Planning, Credit Use and Debt, Budgeting and Keeping Track, Insurance and Protection, Financial Education, Financial Capability }}
          {{ cms:page:country_of_delivery:collection_check_boxes/United Kingdom, England, Northern Ireland, Scotland, Wales, USA, Other }}
          {{ cms:page:client_groups:collection_check_boxes/Children (3-11), Young People (12-16), Parents / Families, Young Adults (17-24), Working Age (18-65), Older People (65+), Over-indebted people, Social housing tenants, Teachers / practitioners, Other }}
          {{ cms:page:data_type:collection_check_boxes/Quantitative, Qualitative }}
        CONTENT
      )
    end
  end
end
