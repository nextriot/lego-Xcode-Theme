#!/usr/bin/ruby
require 'plist'

class String
  def css_classname
    # since class names can't start with underscores or numbers it ends up
    # being easier and more consistent to just start everything with omg_
    "omg_" + gsub(/[%() ]/, '')
  end
end

fork = ARGV.first.split('/').first.css_classname
theme = ARGV.first.split('/').last.gsub(/\.dvtcolortheme$/, '').css_classname


#TODO select color, etc.

%w{
   attribute
   character
   comment
   comment.doc
   comment.doc.keyword
   identifier.class
   identifier.class.system
   identifier.constant
   identifier.constant.system
   identifier.function
   identifier.function.system
   identifier.macro
   identifier.macro.system
   identifier.type
   identifier.type.system
   identifier.variable
   identifier.variable.system
   keyword
   number
   plain
   preprocessor
   string
   url
}

class String
  def parts
    split(' ')[0..2].map{|n| (n.to_f * 255.0).round }
  end
  def rgba
    '#' + parts.map{|n| "%02x" % n}.join('').upcase
  end
  def dark?
    r,g,b = parts.map{|n| n.to_f }
    percievedLuminance = 1 - (((0.299 * r) + (0.587 * g) + (0.114 * b)) / 255)
    percievedLuminance >= 0.5
  end
  def border
    a = "0.25"
    if not dark?
      "rgba(0,0,0,#{a})"
    else
      "rgba(255,255,255,#{a})"
    end
  end
end

plist = Plist::parse_xml(ARGV.first)
bg = plist['DVTSourceTextBackground']
puts <<-EOS
.#{fork}.#{theme} {
  background: #{bg.rgba};
  color: #{plist['DVTSourceTextSyntaxColors']['xcode.syntax.plain'].rgba};
  border-color: #{bg.border};
}
.#{fork}.#{theme} code i::selection, .#{fork}.#{theme} code::selection {
  background: #{plist['DVTSourceTextSelectionColor'].rgba};
}
EOS

# the ::selection selector above doesn't work well for me
# if I make it operate just on .theme_name it doesn't work
# at all!

plist.fetch('DVTSourceTextSyntaxColors').each do |key, value|
  key = key.sub(/^xcode\.syntax\./, '')
  key = case key
  when 'comment', 'number', 'keyword', 'preprocessor', 'string'
    key
  when 'identifier.function', 'identifier.class'
    key.sub(/^identifier\./, '')
  when 'identifier.variable.system'
    'variable'
  when 'identifier.variable'
    'ivar'
  else
    nil
  end
  puts ".#{fork}.#{theme} .#{key} { color: #{value.rgba} }" if key
end
