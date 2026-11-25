#!/usr/bin/env ruby
# frozen_string_literal: true

# Validate shared accessibility and publication contracts in rendered Jekyll output.
require "nokogiri"
require "pathname"
require "date"

site = Pathname.new(ARGV.fetch(0, "_site")).expand_path
pages = site.glob("**/*.html")
abort "No rendered HTML pages found in #{site}" if pages.empty?

errors = []

pages.each do |path|
  relative_path = path.relative_path_from(site)
  document = Nokogiri::HTML(path.read)
  failures = []

  redirect_page = document.css("meta").any? do |meta|
    meta["http-equiv"].to_s.casecmp("refresh").zero?
  end
  if redirect_page
    canonical = document.at_css('link[rel="canonical"]')&.[]("href").to_s
    errors << "#{relative_path}: redirect page is missing its canonical target" if canonical.empty?
    next
  end

  failures << "expected one main landmark" unless document.css("main").length == 1
  failures << "expected one h1" unless document.css("h1").length == 1
  failures << "missing page language" if document.at_css("html")&.[]("lang").to_s.strip.empty?
  failures << "missing page title" if document.at_css("title")&.text.to_s.strip.empty?
  failures << "missing page description" if document.at_css('meta[name="description"]')&.[]("content").to_s.strip.empty?
  failures << "missing canonical link" if document.at_css('link[rel="canonical"]')&.[]("href").to_s.strip.empty?

  viewport = document.at_css('meta[name="viewport"]')&.[]("content").to_s
  if viewport.empty? || viewport.match?(/maximum-scale\s*=\s*1(?:\D|$)|user-scalable\s*=\s*(?:no|0)/i)
    failures << "viewport must permit zoom"
  end

  main = document.at_css('main[id="main-content"][tabindex="-1"]')
  skip_link = document.at_css('a[href="#main-content"]')
  failures << "missing usable skip link" unless main && skip_link

  primary_navigation = document.css("nav[aria-label]").find do |navigation|
    navigation["aria-label"].to_s.match?(/primary/i)
  end
  failures << "missing named primary navigation" unless primary_navigation

  ids = document.css("[id]").map { |element| element["id"] }.reject(&:empty?)
  duplicate_ids = ids.tally.select { |_id, count| count > 1 }.keys
  failures << "duplicate element IDs: #{duplicate_ids.join(', ')}" unless duplicate_ids.empty?

  document.css("img").each do |image|
    failures << "image missing alt: #{image['src']}" unless image.key?("alt")
  end

  document.css("button[aria-controls]").each do |button|
    target_id = button["aria-controls"].to_s
    failures << "navigation control must be type=button" unless button["type"] == "button"
    no_accessible_name = button.text.strip.empty? && button["aria-label"].to_s.strip.empty?
    failures << "navigation control has no accessible name" if no_accessible_name
    failures << "missing controlled element: #{target_id}" unless document.at_xpath("//*[@id=#{target_id.inspect}]")
  end

  failures.each { |failure| errors << "#{relative_path}: #{failure}" }
end

required_outputs = %w[
  index.html
  architecture/index.html
  services/index.html
  faq/index.html
  feed.xml
  sitemap.xml
  releases/index.html
  blog/index.html
  blog/page/2/index.html
  blog/page/3/index.html
  blog/sense-network-service-examples/index.html
  guides/sense-network-service-examples/index.html
  docs/release-notes/index.html
  docs/stable-release/index.html
  docs/publications/index.html
  install-quick-start/index.html
  operational/siterm-operations/index.html
].freeze

required_outputs.each do |relative_path|
  errors << "missing required output: #{relative_path}" unless site.join(relative_path).file?
end

release_articles = site.glob("releases/**/index.html").reject { |path| path == site.join("releases/index.html") }
errors << "expected at least six rendered release articles" if release_articles.length < 6

blog_pages = {
  "blog/index.html" => 10,
  "blog/page/2/index.html" => 10,
  "blog/page/3/index.html" => 8
}.freeze

blog_links = []
blog_pages.each do |relative_path, expected_count|
  path = site.join(relative_path)
  next unless path.file?

  document = Nokogiri::HTML(path.read)
  entries = document.css("[data-blog-entry]")
  errors << "#{relative_path}: expected #{expected_count} blog entries, found #{entries.length}" unless entries.length == expected_count

  entries.each do |entry|
    image = entry.at_css(".blog-card__image img")
    if image.nil?
      errors << "#{relative_path}: blog entry is missing its cover image"
      next
    end

    source = image["src"].to_s
    alt = image["alt"].to_s.strip
    errors << "#{relative_path}: blog cover is missing alternative text: #{source}" if alt.empty?
    if source.start_with?("/")
      asset = site.join(source.delete_prefix("/"))
      errors << "#{relative_path}: blog cover asset does not exist: #{source}" unless asset.file?
    else
      errors << "#{relative_path}: blog cover must be a local asset: #{source}"
    end
  end

  published_dates = entries.filter_map do |entry|
    value = entry["data-published"].to_s
    begin
      Date.iso8601(value)
    rescue Date::Error
      errors << "#{relative_path}: invalid blog publication date #{value.inspect}"
      nil
    end
  end
  unless published_dates.each_cons(2).all? { |newer, older| newer >= older }
    errors << "#{relative_path}: blog entries are not newest first"
  end

  blog_links.concat(entries.filter_map { |entry| entry.at_css(".blog-card__title a")&.[]("href") })
end

errors << "expected 28 unique blog entries, found #{blog_links.uniq.length}" unless blog_links.length == 28 && blog_links.uniq.length == 28

blog_links.uniq.each do |href|
  relative_output = href.delete_prefix("/")
  relative_output = "#{relative_output}index.html" if relative_output.end_with?("/")
  path = site.join(relative_output)
  unless path.file?
    errors << "missing rendered Blog article: #{href}"
    next
  end

  document = Nokogiri::HTML(path.read)
  cover = document.at_css("[data-post-cover] img")
  errors << "#{relative_output}: Blog article is missing its cover image" unless cover
end

first_blog_page = site.join("blog/index.html")
if first_blog_page.file?
  first_title = Nokogiri::HTML(first_blog_page.read).at_css("[data-blog-entry] .blog-card__title")&.text.to_s.strip
  unless first_title == "SENSE QoS on Layer 3 paths: finding the right hosts"
    errors << "blog/index.html: unexpected newest entry #{first_title.inspect}"
  end
end

pagination_contracts = {
  "blog/index.html" => { "next" => "/blog/page/2/" },
  "blog/page/2/index.html" => { "prev" => "/blog/", "next" => "/blog/page/3/" },
  "blog/page/3/index.html" => { "prev" => "/blog/page/2/" }
}.freeze

pagination_contracts.each do |relative_path, links|
  path = site.join(relative_path)
  next unless path.file?

  document = Nokogiri::HTML(path.read)
  links.each do |rel, expected_href|
    href = document.at_css(%(nav.blog-pagination a[rel="#{rel}"]))&.[]("href")
    errors << "#{relative_path}: expected #{rel} link to #{expected_href}, found #{href.inspect}" unless href == expected_href
  end
end

presentation_articles = pages.count do |path|
  Nokogiri::HTML(path.read).at_css("body.layout-presentation")
end
errors << "expected seven rendered presentation articles, found #{presentation_articles}" unless presentation_articles == 7

abort errors.join("\n") unless errors.empty?

puts "Validated accessibility and metadata contracts in #{pages.length} rendered HTML pages."
puts "Validated #{required_outputs.length} required outputs, #{release_articles.length} release articles, and #{presentation_articles} presentation articles."
