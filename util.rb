require 'zipf'
require 'optimist'

def read_stopwords_file fn
  stopwords = {}
  f = ReadFile.new fn
  while line = f.gets
    stopwords[line.strip] = true
  end

  return stopwords
end

def read_vocab_file fn
  if fn.split(".")[-1] == "dbm"
    require 'dbm'
    return DBM.new fn
  else
    vocab = {}
    f = ReadFile.new fn
    while line = f.gets
      count, word = line.split
      vocab[word] = count.to_i
    end

    return vocab
  end
end

# Returns true if string s is only composed of punctuation or brackets
def is_punct s
  return s.match(/^[[[:punct:]]\<\>\[\]\{\}\(\)]+$/)
end

# Returns true if string is all digits
def is_num s
  return s.match(/^[[:digit:]]+$/)
end

# 'Tokenizer' based on spaces
def get_tokens s
  return tokenize s
end

# Returns array of unique tokens and token counts for the string s
def get_types s, stopwords, vocab=nil, rare_threshold=1.0/0
  tokens = get_tokens s
  types = tokens.select { |tok|
    !stopwords.include?(tok) and not is_punct(tok) and not is_num(tok)
  }.uniq

  if vocab
    types = types.select { |t|
      !vocab.fetch(t, nil) || vocab[t].to_i <= rare_threshold
    }
  end

  return types
end

