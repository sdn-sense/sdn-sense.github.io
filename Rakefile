# frozen_string_literal: true

require "rake"

SITE_DIRECTORY = "_site"

namespace :site do
  desc "Build the production Jekyll site"
  task :build do
    command = ["bundle", "exec", "jekyll", "build", "--trace"]
    baseurl = ENV.fetch("JEKYLL_BASEURL", "").strip
    command.concat(["--baseurl", baseurl]) unless baseurl.empty?
    sh({ "JEKYLL_ENV" => ENV.fetch("JEKYLL_ENV", "production") }, *command)
  end

  desc "Validate rendered internal links, images, and scripts"
  task links: :build do
    sh "bundle", "exec", "ruby", "scripts/validate-internal-links.rb", SITE_DIRECTORY
    sh "bundle", "exec", "htmlproofer", SITE_DIRECTORY,
       "--disable-external", "--checks", "Links,Scripts", "--allow-missing-href"
  end

  desc "Validate shared accessibility and required-route contracts"
  task structure: :build do
    sh "bundle", "exec", "ruby", "scripts/validate-site-build.rb", SITE_DIRECTORY
  end

  desc "Validate canonical, social, crawl, and structured SEO metadata"
  task seo: :build do
    sh "bundle", "exec", "ruby", "scripts/validate-seo.rb", SITE_DIRECTORY
  end

  desc "Build and run every site validation"
  task check: %i[links structure seo]
end

task default: "site:check"
