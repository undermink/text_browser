require "net/http"
require "./wrapper.rb"

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

# umlaute
entities = {"&nbsp;" => " ", "&lt;" => "<", "&gt;" => ">",
  "&quot;" => "\"", "&amp;" => "&",
  "&auml;" => "a:", "&ouml;" => "o:", "&uuml;" => "u:",
  "&Auml;" => "A:", "&Ouml;" => "O:", "&Uuml;" => "U:",
  "&szlig;" => "ss"}

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
httpclient = Net::HTTP.new(host, port)

response = httpclient.get(uri)
# Bei 30x-Statuscodes der Weiterleitung folgen
while response.code =~ /^30\d$/
  # Neue URL aus dem Header Location lesen
  location = response['location']
  # Absolute URL gesondert behandeln
  if location =~ %r|^http://(.*)|
    location = $1
    (host, port, uri) = parse_url(location)
    httpclient = Net::HTTP.new(host, port)
  else
    uri = location
  end
  puts "Verfolge Weiterleitung nach #{uri}"
  response = httpclient.get(uri)
end

# Fehlermeldung
if response.code != "200"
  puts
  printf "FEHLER: %s %s\n", response.code, response.message
  puts
end

linkcounter = 0
linksammlung = []


ctype = response['content-type']
if ctype !~ %r|text/|
  puts "\e[H\e[2J"
  puts "RESSOURCE NICHT DARSTELLBAR"
  puts
  puts "Der Typ dieser Ressource ist #{ctype}."
  puts "Dieser Browser kann leider nur Text anzeigen."
  puts
  print "URL => "
else
  body = response.body
  
  # links in Linksammlung aufnehmen
  body.gsub!(/<a.*href="([^"]+)".*>([^<]+)<\/a>/i) {
    linksammlung.push($1)
    linkcounter += 1
    if ($2) == "" 
      "=> #{$1} [#{linkcounter}]"
    else
    "=> #{$2} [#{linkcounter}]"
    end
  }
  
  # umlaute
  entities.each_pair { |ent, repl|
    body.gsub!(ent, repl)
  }
  
  body.gsub!(/<h[1-6]>(.*?)<\/h[1-6]>/mi) {
    $1.upcase + "\n"
  }
  
  # Zeilenumbrueche bei <br />, <p>, <div> und <tr>
  body.gsub!(%r|<br\s*/?>|i, "\n")
  body.gsub!(/<p.*?>/i, "\n")
  body.gsub!(/<div.*?>/i, "\n")
  body.gsub!(/<tr.*?>/i, "\n")

  # Tabelle => Tabulator
  body.gsub!(/<td.*?>/i, "\t")
  
  # sonstiges HTML entfernen
  body.gsub!(/<(script.*|script)>([^<]+)<\/script>/i,"[java-script]")
  js = $2
  body.gsub!(/<.*?>/m, "")
  
  
  # Whitespace zusammenfassen
  body.gsub!(/^\s*\n$/, "\n")
  body.gsub!(/\n{3,}/m, "\n\n")
  body.gsub!(/ {3,}/, " ")
  body.gsub!(/\t+/, "\t")
  
  if linksammlung.length > 0
    body += "\nENTHALTENE LINKS:\n\n"
    linkcounter = 0
    linksammlung.each { |link|
      linkcounter += 1
      body += "#{linkcounter}. #{link}\n"
    }
  end

  wrapper.show(body)

  if linksammlung.length > 0
    puts
    puts "\t----- QUELLCODE: [S][ENTER] [J]avascript -----"
    print "LINK# oder URL => "
  else
    puts
    puts "\t----- QUELLCODE: [S][ENTER]; [J]avascript -----"
    print "URL => "
  end
end

rescue
  puts "Fehler: #{$!}"
  puts "[Pru:fen Sie die URL: #{url}]"
  puts
  print "URL => "
end

begin
  newurl = gets.chomp
end while newurl == ""

break if newurl == "q"

if newurl == "s"
  wrapper.show(httpclient.get(uri).body,false)
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
