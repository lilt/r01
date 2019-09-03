#!/usr/bin/env ruby

require_relative 'util'

def setup reference_file, stopwords_file
  references = ReadFile.readlines_strip reference_file
  stopwords  = read_stopwords_file stopwords_file

  return references, stopwords
end

def stats references, stopwords
  references.each { |r|
    types, uniq_types = get_types r, stopwords

    counts = []
    uniq_types.each { |t|
      counts <<  types.count(t)
    }
    if counts.size > 0
      puts counts.inject(:+) / counts.size.to_f
    end
  }
end

def main
  config = Optimist::options do
    opt :references, "File with references, truecased and tokenized", :type => :string, :short => "-r", :required => true
    opt :stopwords, "File with stopwords, one per line",              :type => :string, :short => "-s", :required => true
  end

  references, stopwords = setup config[:references], config[:stopwords]

  stats references, stopwords
end

main

