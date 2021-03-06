require_relative '../section'

module UI::Sections
  class Header < UI::Section
    element :title, 'h2'
  end

  class Tag < UI::Section
    element :value, 'span'
    element :close, '.close'
  end
end
