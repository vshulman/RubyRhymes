# RubyRhymes is meant to facilitate the creation of automated poetry  
# Authors::    Vlad Shulman (vshulman@github) and Thomas Kielbus (thomas-kielbus@github)
# License::   Distributes under the same terms as Ruby

# this class is the gateway to generating exciting poetry. Use it like this:
#
# >> phrase = "to be or not to beer".to_phrase
# >> phrase.flat_rhymes
# => ["adhere", "alvear", "amir", ...]
# >> "to be or not to beer".to_phrase.syllables
# => 6

class Phrase
  def initialize(phrase)
    @phrase_tokens = Phrase.clean_and_tokenize(phrase)
    
    # [[p1a,p1b],[p2],p3]
    @pronunciations = @phrase_tokens.map{|pt| Pronunciations.get_pronunciations(pt)} #pronunciation objects
    @last_word_pronunciation = @pronunciations.last
  end
  
  # returns the rhyme keys associated with this word (useful in matching with other words to see if they rhyme)
  def rhyme_keys
    @last_word_pronunciation.map(&:rhyme_key).compact||[]
  end
  
  # returns the first rhyme key or nil
  def rhyme_key
    rhyme_keys.first
  end
  
  # returns the number of syllables in the phrase
  def syllables
    @pronunciations.map{|p| p.first.num_syllables}.inject(:+)
  end
  
  # returns whether the last word in the phrase a dictionary word (useful to know before calling rhymes and rhyme_keys)
  def dict?
    @last_word_pronunciation.first.dict?
  end
  
  # returns a map from rhyme key to a list of rhyming words in that key
  def rhymes
    @rhymes = load_rhymes if @rhymes.nil?
    @rhymes
  end
  
  # return a flat array of rhymes, rather than by pronunciation
  def flat_rhymes
    rhymes.empty? ? [] : @rhymes.values.flatten
  end

  # returns the last word in the phrase (the one used for rhyming)
  def last_word
    @last_word_pronunciation.first.word.downcase
  end
  
  private
  
  # lazy loading action
  def load_rhymes
    return {} if !@last_word_pronunciation.first.dict?
      
    rhymes = Hash.new([])
    @last_word_pronunciation.each do |pronunciation|
      rhymes[pronunciation.rhyme_key] = Pronunciations.get_rhymes(pronunciation).map{|x| x.word.downcase}
    end
    rhymes
  end
  
  # we upcase because our dictionary files are upcased
  def self.clean_and_tokenize(phrase)
    phrase.upcase.gsub(/[^A-Z ']/,"").split
  end
  
  # Pronunciations does the heavy lifting, interfacing with the mythical text file of doom
  class Pronunciations
    require 'syllable_arrays'
    
    WORDS_PATH      = "words.txt"
    RHYMES_PATH     = "rhymes.txt"
    MULTIPLES_PATH  = "multiple.txt"

    @@PRONUNCIATIONS = {}          # Pronunciation ID => Pronunciation
    @@MULTIPLE_PRONUNCIATIONS = {} # Word => Pronunciations
    @@RHYMES = {}                  # Rhyme key => Pronunciations

    @@LOADED = false

    def self.get_pronunciations(word)
      load
      pronunciations = @@MULTIPLE_PRONUNCIATIONS[word]
      if pronunciations != nil # Multiple pronunciations case
        return pronunciations
      else # Single or pronunciation case
        pronunciation = get_pronunciation(word)
        if pronunciation
          return [pronunciation]
        else
          return [Pronunciation.new(word, nil, auto_syllables(word.downcase), nil)]
        end
      end
    end

    # Returns arrays of rhymes -- an Array of rhymes for each pronunciation
    def self.get_rhymes(pronunciation)
      load
      rhymes = []
      rhymes = @@RHYMES[pronunciation.rhyme_key]
      rhymes.delete(pronunciation)
      rhymes
    end

  private

    def self.get_pronunciation(pronunciation_id)
      @@PRONUNCIATIONS[pronunciation_id]
    end

    def self.get_word_from_pronunciation_id(pronunciation_id)
      return pronunciation_id.split('(')[0]
    end
    
    # based entirely off of http://www.russellmcveigh.info/content/html/syllablecounter.php
    def self.auto_syllables(word)
      valid_word_parts = []
      word_parts = word.split(/[^aeiouy]+/).each do |value|
        if !value.empty?
          valid_word_parts << value
        end
      end

      syllables = 0;
      # Thanks to Joe Kovar for correcting a bug in the following lines
      SYBSYL.each {|syl| syllables -= (syl.match(word).nil? ? 0 : 1) }

      ADDSYL.each {|syl| syllables += (syl.match(word).nil? ? 0 : 1) }

      # UBER EXCEPTIONS - WORDS THAT SLIP THROUGH THE NET
      syllables -= 1 if EXCEPTIONS_ONE.include?(word)

      syllables += valid_word_parts.count
      syllables = (syllables == 0) ? 1 : syllables
    end
    
    # initialization occurs here
    def self.load(words_path = WORDS_PATH, rhymes_path = RHYMES_PATH, multiple_pronunciations_path = MULTIPLES_PATH)
      return if @@LOADED
      File.open(File.expand_path("../#{words_path}", __FILE__), "r") do |lines|
        while (line = lines.gets)
          parts = line.split(" ");
          pronunciation_id = parts[0]
          word = get_word_from_pronunciation_id(pronunciation_id)
          num_syllables = parts[2].to_i
          rhyme_key = parts[1]
          @@PRONUNCIATIONS[pronunciation_id] = Pronunciation.new(word, pronunciation_id, num_syllables, rhyme_key)
        end
      end
      
      File.open(File.expand_path("../#{multiple_pronunciations_path}", __FILE__), "r") do |lines|
        while (line = lines.gets)
          pronunciations = line.split(" ");
          word = pronunciations.slice!(0)
          pronunciations.map! do |p|
            @@PRONUNCIATIONS[p]
          end
          pronunciations.reject!(&:nil?)
          @@MULTIPLE_PRONUNCIATIONS[word] = pronunciations
        end
      end

      File.open(File.expand_path("../#{rhymes_path}", __FILE__), "r") do |lines|
        while (line = lines.gets)
          parts = line.split(" ");
          rhyme_key = parts.slice(0)
          rhyme_pronunciations = parts.slice(1..-1)
          rhyme_pronunciations.map! {|p| @@PRONUNCIATIONS[p]}
          @@RHYMES[rhyme_key] = rhyme_pronunciations
        end
      end
      @@LOADED = true
    end
  end
  
  # a container of word, pronunciation_id, num_syllables, and rhyme_key
  class Pronunciation
    attr_reader :word, :pronunciation_id, :num_syllables, :rhyme_key

    def initialize(word, pronunciation_id, num_syllables, rhyme_key)
      @word = word
      @pronunciation_id = pronunciation_id
      @num_syllables = num_syllables
      @rhyme_key = rhyme_key
    end
    
    # dictionary word?
    def dict?
      !!@pronunciation_id
    end
    
    def to_s
      word
    end
  end
end

class String
  def to_phrase
    Phrase.new(self)
  end
end