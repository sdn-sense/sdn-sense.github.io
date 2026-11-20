#!/usr/bin/env ruby
# frozen_string_literal: true

# Validate shared accessibility and publication contracts in rendered Jekyll output.
require "nokogiri"
require "pathname"

site = Pathname.new(ARGV.fetch(0, "_site")).expand_path
pages = site.glob("**/*.html")
abort "No rendered HTML pages found in #{site}" if pages.empty?

errors = []

pages.each do |path|
  relative_path = path.relative_path_from(site)
  document = Nokogiri::HTML(path.read)
  failures = []

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
  feed.xml
  sitemap.xml
  releases/index.html
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

abort errors.join("\n") unless errors.empty?

puts "Validated accessibility and metadata contracts in #{pages.length} rendered HTML pages."
puts "Validated #{required_outputs.length} required outputs and #{release_articles.length} release articles."
