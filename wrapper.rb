class Wrapper
  def show(text,page=true)
    # nach 70 Zeichen
    # an einer Wortgrenze umbrechen
    text.gsub!(/(.{1,70})(\s+|\Z)/, "\\1\n")
    size = `stty size`
    textlines = text.split("\n")
    line = 0
    while (textlines != [])
      while (line < size[0..1].to_i-1)
        l = textlines.shift
        if l == nil
          ende = true
          break
        end
        puts l
        line += 1
      end
      #break if ende
      if !ende
        print "\n\t----- WEITER: [ENTER]; ENDE: [Q] -----"
        weiter = STDIN.gets.chomp
        break if weiter == "q"
        line = 0
      else
        break if page
        print "\n\t----- ZURU:CK -----"
        gets
      end
    end
  end
end