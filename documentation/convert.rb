#!/usr/bin/env ruby

require 'rubygems'
require 'redcloth'
require 'erb'
require 'hpricot'
require 'syntax/convertors/html'

class Section
  class <<self
    def initialize
      @no_title_index = 0
    end
    def next_no_title
      "No title #{next_no_title_index}"
    end
    protected
    def next_no_title_index
      @no_title_index += 1
    end
  end
  attr_reader :name
  attr_reader :depth
  attr_accessor :children
  attr_accessor :parent
  def initialize(name, depth)
    @name = name
    @depth = depth
    @children = []
  end
  def anchor
    return nil if name.nil?
    name.downcase.gsub(/ /, "_")
  end
  def root?
    name.nil?
  end
  def add_child(section)
    children << section
    section.parent = self
    section
  end
  def number_path
    p = []
    s = self
    section = parent
    while !section.nil?
      p = p.unshift(section.children.index(s) + 1)
      s = section
      section = section.parent
    end
    p.join(".")
  end
  def name_with_options
    "#{number_path}. #{name}"
  end
end

class Converter
  attr_accessor :content_file, :title, :template_file
  def initialize(content_file, options={})
    @content_file = content_file
    @title = options[:title] || 'ActiveWarehouse'
    @template_file = options[:template] || 'template.html.erb'
  end
  
  # Get the content passed through RedCloth
  def content
    return @content if @content
    rc = RedCloth.new(syntax_highlight(File.read(content_file)))
    rc.hard_breaks = false
    rc.no_span_caps = true
    @content = rc.to_html
  end
  
  # Merge the HTML formatted content with the template for the final product
  def convert
    erb = ERB.new(File.readlines(template_file).join)
    File.open(File.basename(content_file, File.extname(content_file)) + '.html', 'w') do |f|
      f << erb.result(get_binding)
    end
  end
  
  # Get the content with the table of contents injected.
  def content_with_toc
    root = Section.new(nil, 0)
    section = root
    content_with_toc = []
    content.split(/\n/).each do |line|
      line.gsub!(/(<h([1-6])>(.*)<\/h[1-6]>)/) do |s|
        tag = $1; depth = $2.to_i; name = $3
        if section.depth == depth
          section = section.parent.add_child Section.new(name, depth)
        elsif section.depth == depth - 1
          section = section.add_child Section.new(name, depth)
        elsif section.depth > depth
          while section.depth > depth
            section = section.parent
          end
          section = section.parent.add_child Section.new(name, depth)
        elsif section.depth < depth - 1
          while section.depth < depth - 1
            section = section.add_child Section.new(Section.next_no_title, section.depth + 1)
          end
          section = section.add_child Section.new(name, depth)
        end
        %Q{<a name="#{section.anchor}"><h#{section.depth}>#{section.name_with_options}</h#{section.depth}></a>}
      end
      
      content_with_toc << line
    end
    
    toc_html = %Q{<div class="toc">#{toc(root)}</div>}
    content_with_toc.unshift(toc_html).join("\n")
  end
  
  def syntax_highlight(s)
    doc = Hpricot(s)
    %w(ruby xml yml).each do |lang|
      (doc/"div[@class='#{lang}']").each do |code_element|
        convertor = Syntax::Convertors::HTML.for_syntax(lang)
        code_element.inner_html = convertor.convert(code_element.inner_html.strip, false)
      end
    end
    (doc/'div').each do |code_element|
      code_element.inner_html = code_element.inner_html.strip
    end
    doc.to_html
  end
  
  def get_binding
    binding
  end
  
  # Construct the HTML for the table of contents
  def toc(section, h='')
    if !section.root?
      h << (" " * (section.depth - 1))
      h << %Q{<li><a href="##{section.anchor}">#{section.name_with_options}</a>}
    end
    
    if !section.children.empty?
      h << "\n" + (" " * section.depth) + "<ul>\n"
      section.children.each do |child|
        toc(child, h)
      end
      h << (" " * section.depth) + "</ul>\n"
      h << (" " * (section.depth - 1)) unless section.root?
    end
    h << "</li>\n" unless section.root?
    h
  end
  
  private
  # Debug method
  def print_section(section)
    puts (" " * (section.depth - 1)) + "#{section.name}" unless section.root?
    section.children.each do |child|
      print_section(child)
    end
  end
end

def usage
  puts "Usage: ./convert.rb file1 [file2 file3 ...]"
end

if ARGV.length == 0
  usage()
else
  ARGV.each do |filename|
    puts "Converting #{filename}"
    converter = Converter.new(filename)
    converter.convert
  end
end