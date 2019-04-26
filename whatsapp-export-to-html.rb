Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'ostruct'
messages = []

def message(info = {})
  OpenStruct.new(
    meta: info.fetch(:meta, ''),
    speaker: info.fetch(:speaker, ''),
    text: info.fetch(:text, '')
  )
end

def attach(text)
  img_attachment_text_matcher = /<Anhang: (.*?\.jpg)>/i
  vid_attachment_text_matcher = /<Anhang: (.*?\.mp4)>/i

  if img = img_attachment_text_matcher.match(text)
    text = text.gsub(img_attachment_text_matcher, "<img src=\"media/#{img.to_a[1]}\"></img>")
  elsif vid = vid_attachment_text_matcher.match(text)
    text = text.gsub(vid_attachment_text_matcher, "<video controls src=\"media/#{vid.to_a[1]}\"></img>")
  else
    text
  end
end

new_message_matcher = /\[(\d\d\.\d\d\.\d\d, \d\d:\d\d:\d\d)\] (.*?): (.*)/

File.open("media/_chat.txt").each do |line|
  l, meta, speaker, text = new_message_matcher.match(line).to_a

  if l.nil?
    m = messages.last
    m.text = "#{m.text}<br>#{attach(line)}"
  else
    messages << message(meta: meta, speaker: speaker, text: attach(text))
  end
end

def output_message(message, viewpoint)
  if message.speaker == viewpoint
    "<tr><td></td><td><p class=\"meta\">#{message.meta} | #{message.speaker}</p><p class=\"content\">#{message.text}</p></td></tr>"
  else
    "<tr class=\"other\"><td><p class=\"meta\">#{message.meta} | #{message.speaker}</p><p class=\"content\">#{message.text}</p></td><td></td></tr>"
  end
end

File.open("chat.html", "w") do |file|
  file.puts "<!DOCTYPE html>
  <html>
    <head>
      <title>Chat</title>
      <meta charset=\"utf-8\">
      <style>
        *{font-family:sans-serif; line-height:1.5;}
        table{width:100%; border-collapse:collapse;}
        tr.other{background-color:#ddd;}
        td{width:50%; word-wrap:break-word; padding:0.3em;}
        img{width:100%;}
        video{width:100%;}
        p{margin:0;}
        p.meta{font-size:75%; text-decoration:underline; margin:0; margin-bottom:0.5em;}
      </style>
    </head>
    <body>
      <table>"
  viewpoint = ENV.fetch("WHATSAPP_EXPORT_VIEWPOINT", messages.first.speaker) 
  messages.each do |m|
    file.puts output_message(m, viewpoint)
  end
  file.puts "</table></body></html>"
end

