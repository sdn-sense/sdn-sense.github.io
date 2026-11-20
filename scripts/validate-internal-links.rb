#!/usr/bin/env ruby
# frozen_string_literal: true

require "nokogiri"
require "pathname"
require "uri"

site = Pathname.new(ARGV.fetch(0, "_site")).expand_path
abort "No rendered site at #{site}" unless site.directory?

errors = []

def output_path(site, url_path)
  clean = URI.decode_www_form_component(url_path).sub(%r{\A/+}, "")
  candidate = site.join(clean)
  return candidate if candidate.file?
  return candidate.join("index.html") if candidate.directory?
  return site.join("#{clean}.html") if File.extname(clean).empty? && site.join("#{clean}.html").file?

  candidate
end

site.glob("**/*.html").each do |source|
  document = Nokogiri::HTML(source.read)
  source_url = "/#{source.relative_path_from(site)}".sub(%r{/index\.html\z}, "/")

  document.css("a[href], img[src], script[src], link[href]").each do |element|
    attribute = element["href"] ? "href" : "src"
    raw = element[attribute].to_s.strip
    next if raw.empty? || raw.start_with?("mailto:", "tel:", "data:", "javascript:")

    uri = URI.parse(raw)
    next if uri.host

    path = uri.path.to_s
    if path.empty?
      target = source
    elsif path.start_with?("/")
      target = output_path(site, path)
    else
      base = source_url.end_with?("/") ? source_url : File.dirname(source_url)
      resolved = URI.join("https://sdn-sense.dev#{base}", path).path
      target = output_path(site, resolved)
    end

    unless target.file?
      errors << "#{source.relative_path_from(site)}: missing #{raw}"
      next
    end

    next if uri.fragment.to_s.empty? || target.extname != ".html"

    target_document = target == source ? document : Nokogiri::HTML(target.read)
    fragment = URI.decode_www_form_component(uri.fragment)
    found = target_document.xpath('//*[@id=$id or @name=$id]', nil, id: fragment).any?
    errors << "#{source.relative_path_from(site)}: missing fragment ##{fragment} in #{raw}" unless found
  rescue URI::InvalidURIError, ArgumentError => error
    errors << "#{source.relative_path_from(site)}: invalid #{attribute} #{raw.inspect} (#{error.message})"
  end
end

abort errors.uniq.sort.join("\n") unless errors.empty?

puts "Validated rendered internal links and assets."
