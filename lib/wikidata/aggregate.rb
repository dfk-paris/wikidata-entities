require 'csv'
require 'json'
require 'digest'

require 'bundler'
Bundler.require

module Wikidata

end

module Wikidata::Aggregate
  def self.run
    people = pb + own_reality + dfkv
    people = combine(people)
    people = generate_dfk_ids(people)
    to_csv(people)
  end

  def self.dfk_ids
    @dfk_ids ||= {}
  end

  def self.new_id(batch)
    @ids ||= []
    candidate = nil
    until candidate && !@ids.include?(candidate)
      candidate = (rand * 10**7).to_i
    end
    @ids << candidate
    candidate

    "DFK#{'%03d' % batch}#{'%07d' % candidate}"
  end

  def self.generate_dfk_ids(people)
    dfk_ids = {}

    people.map do |person|
      person.merge('dfk_id' => new_id(0))
    end
  end

  def self.to_csv(people)
    headers = [
      'wikidata_id',
      'label',
      'deleted',
      'dfk_id',
      'or_id', 'or_label',
      'dfkv_id', 'dfkv_label',
      'pb_id', 'pb_label'
    ]

    out = CSV.generate do |csv|
      csv << headers
      csv << headers
      people.each do |person|
        csv << headers.map{|h| person[h]}
      end
    end

    File.open 'frontend/public/entities.csv', 'w+' do |f|
      f.write out
    end
  end

  def self.combine(people)
    results = []
    wikidata = {}

    people.each do |person|
      source = person['source']
      qid = person['wikidata_id']

      record = {
        "#{source}_id" => person['source_id'],
        "#{source}_label" => person['label'],
        'deleted' => person['deleted']
      }

      if !person['label']
        puts "record #{person} doesn't have a label"
        record['deleted'] = 'yes'
      end

      if qid
        record['wikidata_id'] = qid
        wikidata[qid] ||= {}
        wikidata[qid].merge!(record)
      else
        results << record
      end
    end

    results + wikidata.values
  end

  def self.dfkv
    url = 'https://github.com/dfk-paris/dfkv/raw/ng/data/DFKV_Master.xlsx'
    file = '/tmp/DFKV_Master.xlsx'
    system 'curl', '--silent', '-L', '-o', file, url

    results = {}

    people = read_excel(file, "Personnes", 'id', 2)
    seen = {}
    people.each do |id, person|
      qid = person['wikidata_id']
      id2 = person['id_2']

      # if qid
      #   next if seen[qid]
      #   seen[qid] = true
      # end

      results[id2] ||= {
        'source' => 'dfkv',
        'wikidata_id' => qid,
        'source_id' => id2,
        'other_labels' => []
      }

      if person['label'] == 1
        results[id2]['label'] = person['display_name']
      else
        results[id2]['other_labels'] << person['display_name']
      end

      if [100047, 100304, 100305].include?(id2)
        results[person['id_2']]['deleted'] = 'yes'
      end
    end

    results.values
  end

  def self.own_reality
    url = 'https://github.com/dfk-paris/OR_heidata/raw/master/people-data-json-csv_0226.xlsx'
    # can't be downloaded, private repo
    # system 'curl', '--silent', '-L', '-o', file, url
    # file = '/tmp/or-people.xlsx'
    file = '../cache/or-people.xlsx'

    results = []

    people = read_excel(file, "people data json csv_0226 xls", 'ID')
    people.each do |id, person|
      next if person['ID_2']

      results << {
        'source' => 'or',
        'wikidata_id' => person['Wiki_Q'],
        'source_id' => person['ID'],
        'label' => person['full name'],
        'original' => person
      }
    end

    results
  end

  def self.pb
    response = Faraday.get('https://pb.dfkg.org/api/people')
    people = JSON.parse(response.body)

    results = []

    people.each do |label, qid|
      clean_label = label.
        gsub(/, zugeschrieben.*/, '').
        gsub(/ \([\d\-]+\)/, '')

      results << {
        'source' => 'pb',
        'wikidata_id' => qid,
        'source_id' => qid,
        'label' => clean_label,
        'original' => {label => qid}
      }
    end

    results
  end

  def self.read_excel(file, sheet_name, primary_key = 'id', header_row = 1)
    # puts "reading sheet '#{sheet_name}' from '#{file}'"

    book = Roo::Spreadsheet.open(file)
    sheet = book.sheet_for(sheet_name)

    headers = sheet.row(1).map.with_index{|e, i| sheet.row(header_row)[i] }
    results = {}
    ((header_row + 1)..sheet.last_row).each do |i|
      values = sheet.row(i)
      record = headers.zip(values).to_h.reject do |k, v|
        k.nil? || v.nil? || v == ''
      end
      # binding.pry if sheet_name == 'Data_complet'
      results[record[primary_key]] = record
    end
    
    book.close
    results
  end
end
