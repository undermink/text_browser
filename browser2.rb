require "./wrapper.rb"
require "nokogiri"
require "open-uri"

# URL in Host, Port und Ressource zerlegen

def parse_url(url)
  if url.match(%r|([^/]+)(/.*)|)
  host = $1
  uri = $2
  end
  # Gegebenenfalls Host und Portnummer trennen
  if host =~ /:/
    (host, port) = host.split(":")
  port = port.to_i
  else
  port = 80
  end
  # Alle drei Komponenten zurueckgeben
  [host, port, uri]
end

wrapper = Wrapper.new

begin
  puts "\e[H\e[2J"
  puts "welcome to undermink's text-browser"
  puts "-----------------------------------"
  puts
  print "URL => "
  url = gets.chomp
end while url == ""

# Hauptschleife
loop do
  # / anfuegen, falls URL keinen enthaelt
  if url !~ %r|/|
  url += "/"
end

# URL zerlegen
(host, port, uri) = parse_url(url)
puts "\e[H\e[2J"
puts "Hole #{uri} von #{host}:#{port}"

begin
response = Nokogiri::HTML(open('http://'+host+uri))
end

linkcounter = 0
linksammlung = []

body=""
response.css('body').each do |text|
  body+=text.content
end

response.css('a').each do |lnk|
	linksammlung.push(lnk['href'])
	linkcounter+=1
end  
  #body.gsub!(/<(script.*?|script)>([^<]+)<\/script>/i,"[java-script]")
js = nil
  #js = $2
if linksammlung.length > 0
  body += "\n\n\t----- ENTHALTENE LINKS: -----\n\n"
  linkcounter = 0
  linksammlung.each { |link|
    linkcounter += 1
    body += "#{linkcounter}. #{link}\n"
  }
end

wrapper.show(body)

if linksammlung.length > 0
    puts "\n\t----- [S]OURCECODE - [J]avascript -----"
    print "LINK# oder URL => "
else
    puts "\n\t----- [S]OURCECODE - [J]avascript -----"
    print "URL => "
end

begin
  newurl = gets.chomp
end while newurl == ""

break if newurl == "q"

if newurl == "s"
  wrapper.show(response.to_s,false)
  newurl = url
end

if newurl == "j"
  if js == nil
    js = "\n\t...ich konnte kein javascript finden...\n"    
  end
  wrapper.show(js,false)
  newurl = url
end

  if newurl =~ /^[0-9]+$/
    # URL bilden aus Linknummer
    newurl = linksammlung[newurl.to_i - 1]
  if newurl =~ /^#/
    
  elsif newurl =~ %r|^http://(.*)|
    url = $1
  elsif newurl =~ %r|^/|
    url = host + newurl
  else
    url.gsub!(%r|(.*)/.*|, "\\1")
    url += "/" + newurl
  end
else
  url = newurl
end
end
