#!/usr/bin/env ruby

require_relative  'util'

def setup reference_file=nil, hypotheses_file=nil, stopwords_file=nil
  references = ReadFile.readlines_strip reference_file
  hypotheses = ReadFile.readlines_strip hypotheses_file
  stopwords  = read_stopwords_file stopwords_file

  return references, hypotheses, stopwords
end

def rk references,
       hypotheses,
       stopwords,
       k,
       combined=false,
       vocab=nil,
       rare_threshold=1.0/0,
       cumulative=false,
       per_segment=false,
  occurrences = {}; occurrences.default = 0
  total = 0
  enumerator = 0
  if not combined then cmp = :== else cmp = :<= end  # == for R0 and R1, <= for R01
  hypotheses.each_index { |i|                        # Inputs are all assumed to be tokenized and truecased
    r = get_types references[i], stopwords, vocab, rare_threshold
    h = get_types hypotheses[i], stopwords, vocab, rare_threshold
    current_total = current_enumerator = 0
    r.each { |t|
      occurrences[t] += 1                            # Count occurrences

      # Denominator
      if occurrences[t].public_send(cmp, k+1)        # Count exact occurence count, or up to k+1
        total += 1.0
        current_total += 1.0
      end

      # Enumerator
      if h.include? t                                # Match!
        if occurrences[t].public_send(cmp, k+1)      # k+1th occurrence, kth-shot
          enumerator += 1
          current_enumerator += 1
        end
      end
    }

    if per_segment
      begin
        puts current_enumerator/current_total
      rescue
        puts 0.0
      end
    end

    if cumulative
      begin
        puts enumerator/total
        #puts total
      rescue
        puts 0.0
      end
    end
  }

  return enumerator, total
end

def main
  config = Optimist::options do
    opt :input, "File with hypotheses, truecased and tokenized",       :type => :string, :short => "-i", :default => '-'
    opt :references, "File with references, truecased and tokenized",  :type => :string, :short => "-r", :required => true
    opt :stopwords, "File with stopwords, one per line",               :type => :string, :short => "-s", :required => true
    opt :k, "Allow k-shot matches",                                    :type => :int,    :short => "-k", :default => 1
    opt :vocab, "Vocab. file, format: <count> <word>",                 :type => :string, :short => "-v", :default => nil
    opt :rare_threshold, "Max. count up to a word is counted as rare", :type => :int,    :short => "-R", :default => 0
    opt :zero_shot, "Zero-shot (R0) metric",                           :type => :bool,   :short => "-Z", :default => false
    opt :one_shot, "One-shot (R<k>) metric",                           :type => :bool,   :short => "-O", :default => false
    opt :combined, "R0<k> metric",                                     :type => :bool,   :short => "-C", :default => false
    opt :cumulative, "Output cumulative scores",                       :type => :bool,   :short => "-c", :default => false
    opt :per_segment, "Output per-segment scores",                     :type => :bool,   :short => "-p", :default => false
  end

  references, hypotheses, stopwords = setup config[:references], config[:input], config[:stopwords]

  if config[:per_segment] and config[:cumulative]
    puts "Won't output both per-segment _and_ cumulative scores, exiting!"
    exit
  end

  if config[:vocab]
    vocab = read_vocab_file config[:vocab]
  else
    vocab = nil
  end

  scores = {}
  hits = {}
  totals = {}

  ks = []
  if config[:zero_shot] then ks << 0 end
  if config[:one_shot] then ks << config[:k] end

  ks.each { |k|
    enumerator, total  = rk references, hypotheses, stopwords, k, false, vocab, config[:rare_threshold], config[:cumulative], config[:per_segment]
    scores["R#{k}"] = enumerator / total
    hits["R#{k}"] = enumerator
    totals["R#{k}"] = total
  }

  if config[:combined]
    enumerator, total = rk references, hypotheses, stopwords, config[:k], true, vocab, config[:rare_threshold], config[:cumulative], config[:per_segment]
    scores["R0#{config[:k]}"] = enumerator / total
    hits["R0#{config[:k]}"] = enumerator
    totals["R0#{config[:k]}"] = total
  end

  if not config[:cumulative] and not config[:per_segment]
    puts scores.map { |name,value|
      "#{name}=#{(value*100.0).round 2} [#{hits[name]}/#{totals[name].to_i}]"
    }.join "\t"
  end
end

main

