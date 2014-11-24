FactoryGirl.define do
  factory :file, class: Comfy::Cms::File do
    site
    label 'Default File'
    sequence(:file_file_name) { |n| "sample-#{n}.jpg" }
    file_content_type 'image/jpeg'
    file_file_size 20099
    description 'Default Description'
    position 0
  end
end
