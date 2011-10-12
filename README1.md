# RubyRhymes
RubyRhymes is a gem that makes auto-generating terrible poetry a breeze. You use it roughly like so:

    >> "RubyGems... is a gem quite sublime!".to_phrase.flat_rhymes
    => ["anticrime", "beim", "chime", "climb", "clime", "crime", ...]

## Requirements
Tested with Ruby 1.8.7

## Installation

    gem install ruby_rhymes
  
## Usage
The easiest thing to do is embrace the String abuse:

    >> "RubyRhymes is a gem quite sublime".to_phrase.flat_rhymes
    => ["anticrime", "beim", "chime", "climb", "clime", "crime", ...]

The first time you call most methods on a `Phrase` class (which is what these things are), the gem constructs the (static) in-memory dictionary, so expect a minor delay and some inevitable om-nom-nom-ing of memory.

Alright, what else we got? how about a some good ol' syllable countin', like in the old country?

    >> "RubyRhymes is a gem quite sublime".to_phrase.syllables
    => 9
    
oh, how nice. Notice how even though _RubyRhymes_ is not a dictionary word, we still got a pretty solid syllable estimate. That's what happens when you plagiarize from enough smart people on the internet. Note however that that's the extent of magic - calling `.flat_rhymes` on a non-dictionary word will return a lonely, desolate array:
    
    >> "blog".to_phrase.flat_rhymes
    => []

Don't want to deal with silly phrases that don't end in dictionary words? there's a method for that:

    >> "can i haz lolcats?".to_phrase.dict?
    => false

All by yourself one night, you may find that you're trying to figure out which sentences rhyme in a corpus of text:

    >> "do you see a dog?".to_phrase.rhyme_keys
    => ["&C"]
    >> "through the sailing fog!".to_phrase.rhyme_keys
    => ["&C"]
    
that's useful, you can now `group_by` (Rails) or whatever you're into. Notice I called `.rhyme_keys` instead of `.rhyme_key`. That's because words with multiple pronunciations may have multiple rhyme keys (*tomato* returns ["\\2R", "\\2:"]). You can still call `.rhyme_key` and that will just call `.first` for you - it's on the house. You'll get a `nil`/`[]` from these _key/keys_ methods iff `.dict?` is _false_, so keep that in mind and don't assume that two words with a key of `nil` rhyme.

If you're not afraid of multiple pronunciations, you can call `.rhymes` instead of `.flat_rhymes` which will yield a map from rhyme key to rhymes. For a dictionary word with no rhymes (orange) it will still return a map to an empty array, whereas for _.dict? == false_ expect `{}`

    >> "RubyRhymes is a gem quite sublime".to_phrase.rhymes
    => {"+I"=>["anticrime", "beim", "chime", "climb", "clime", "crime", ...]}
    
## Props

- [Thomas](https://github.com/thomas-kielbus "github"), the co-author extraordinaire and Andre, my muse
- The dictionaries, which is really what matters, came from [Brian Langenberger](http://rhyme.sourceforge.net/index.html "Rhyme Dictionary"), whose work was based on a [CMU Pronouncing Dictionary](http://www.speech.cs.cmu.edu/cgi-bin/cmudict CMU Dictionary).
- The syllable counter for words that aren't in the dictionary comes from the source made available by [Russell McVeigh](http://www.russellmcveigh.info/content/html/syllablecounter.php "PHP Syllable Counter"). I just ported the PHP.

## Modus Operandi
In essence we have three dictionaries available

- _multiple.txt_ : Word to pronunciation-encoding (ex. TOMATO => TOMATO TOMATO(2))
- _words.txt_ : Pronunciation-encoding to syllable rhyme key and syllable count (ex. TOMATO => \2R 3)
- _rhymes.txt_ : Rhyme-key to pronunciation-encodings of words that rhyme with it (ex. \2R => POTATO SAITO TOMATO)

from here on, it's fairly intuitive what needs to be done. `multiple.txt` is only has keys when the word actually has multiple pronunciations, so _CAT_ will yield nothing there, meaning we can continue to check in `words.txt`.

## TODO
