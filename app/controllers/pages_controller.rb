class PagesController < Comfy::Admin::Cms::PagesController
  before_action :build_file,     only: [:new, :edit]
  before_action :set_categories, only: [:new, :edit]
  before_action :set_pages,      only: :index
  before_action :set_activity_log, only: [:new, :edit]

  def save_page
    PageRegister.new(@page, params: params, current_user: current_user).save
  end

  protected

  def set_activity_log
    @activity_logs = ActivityLogPresenter.collect(ActivityLog.fetch(from: @page))
  end

  def set_pages
    @pages = @site.pages.unscoped.includes(:layout, :site)
  end

  def apply_filters
    @filters_present = params[:category].present? || params[:search].present?

    if params[:search].present?
      Comfy::Cms::Search.new(@pages, params[:search]).results
    else
      filter_params = params.slice(:category, :layout, :last_edit, :status, :language)
      @pages.filter(filter_params).order(updated_at: :desc).page(params[:page])
    end
  end

  def build_file
    @file = Comfy::Cms::File.new
  end

  def set_categories
    @categories = Comfy::Cms::CategoriesListPresenter.new(@site.categories.of_type('Comfy::Cms::Page'))
  end
end