require ComfortableMexicanSofa::Engine.root.join('app', 'models', 'comfy', 'cms', 'page.rb')

class Comfy::Cms::Page < ActiveRecord::Base
  scope :ignore_suppressed, -> { where(suppress_from_links_recirculation: false) }

  scope :most_popular, (lambda do |number_of_items|
    unscoped
      .order('page_views desc')
      .ignore_suppressed
      .limit(number_of_items)
  end)

  scope :with_tags, -> (tags) { joins(:taggings).where('taggings.tag_id' => tags.map(&:id)) }

  scope :remove_self_from_results, -> (page) { where.not(id: page.id) }

  scope :sort_by_tag_similarity, (lambda do |keywords|
    with_tags(keywords)
      .group('comfy_cms_pages.id')
      .order('COUNT(*) DESC, comfy_cms_pages.page_views DESC')
    # This counts the number of tags each article has in common
    # with the article we're querying against,
    # then sorts by that number, then the page views.
  end)

  scope :all_english_articles, (lambda do
    joins(:layout)
      .joins(:site)
      .where(
        comfy_cms_sites: { label: 'en' },
        comfy_cms_layouts: { identifier: 'article' }
      )
  end)

  def update_page_views(analytics)
    matching_analytic = analytics.find { |analytic| analytic[:label] == slug }
    new_page_views = matching_analytic.present? ? matching_analytic[:page_views] : 0
    update_attribute(:page_views, new_page_views)
  end

  def related_links(limit)
    mirrored_page = PageMirror.new(self).mirror(:en)

    Comfy::Cms::Page
      .unscoped
      .all_english_articles
      .ignore_suppressed
      .sort_by_tag_similarity(keywords)
      .remove_self_from_results(self)
      .where.not(id: mirrored_page.try(:id))
      .limit(limit)
  end

  def suppress_mirrors_from_links_recirculation
    mirrors.each do |mirror|
      mirror.update_column(:suppress_from_links_recirculation, suppress_from_links_recirculation)
    end
  end
end