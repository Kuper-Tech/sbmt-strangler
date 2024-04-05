# frozen_string_literal: true

# See compatibility table at https://www.fastruby.io/blog/ruby/rails/versions/compatibility-table.html

versions_map = {
  "7.0" => %w[3.1],
  "7.1" => %w[3.2 3.3]
}

current_ruby_version = RUBY_VERSION.split(".").first(2).join(".")

versions_map.each do |rails_version, ruby_versions|
  ruby_versions.each do |ruby_version|
    next if ruby_version != current_ruby_version

    appraise "railties-#{ruby_version}-#{rails_version}" do
      gem "railties", "~> #{rails_version}.0"
    end
  end
end
