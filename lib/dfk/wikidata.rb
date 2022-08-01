require 'csv'
require 'json'
require 'digest'

require 'bundler'
Bundler.require

module Dfk
end

module Dfk::Wikidata
  def self.run
    people = pb + own_reality + dfkv
    people = combine(people)
    people = generate_dfk_ids(people)
    to_csv(people)
    to_json(people)
  end

  def self.dfk_ids
    @dfk_ids ||= {}
  end

  def self.new_id(base)
    hash = Digest::SHA2.hexdigest(base)
    num = hash.
      unpack('C*').
      select.with_index{|e, i| i % 16 == 0}.
      pack('C*').
      unpack('L*').
      first
    candidate = "DFK1#{num}"

    dfk_ids[candidate] ? new_id(hash) : candidate
  end

  def self.generate_dfk_ids(people)
    dfk_ids = {}

    people.map do |person|
      base = person['wikidata_id'] || begin
        id = [
          "QNOQ",
          "or:#{person['or_id']}",
          "dfkv:#{person['dfkv_id']}",
          "pb:#{person['pb_label']}"
        ].join('-')
      end

      person.merge('dfk_id' => new_id(base))
    end
  end

  def self.to_csv(people)
    headers = [
      'wikidata_id',
      'dfk_id',
      'or_id', 'or_label',
      'dfkv_id', 'dfkv_label',
      'pb_id', 'pb_label'
    ]

    out = CSV.generate do |csv|
      csv << headers
      people.each do |person|
        csv << headers.map{|h| person[h]}
      end
    end

    File.open 'data/entities.csv', 'w+' do |f|
      f.write out
    end
  end

  def self.to_json(people)
    out = JSON.pretty_generate(people)

    File.open 'data/entities.json', 'w+' do |f|
      f.write out
    end
  end

  def self.combine(people)
    results = []
    wikidata = {}

    people.each do |person|
      source = person['source']
      qid = person['wikidata_id']

      if qid
        wikidata[qid] ||= {}
        wikidata[qid]['wikidata_id'] = qid
        wikidata[qid]["#{source}_id"] = person['source_id']
        wikidata[qid]["#{source}_label"] = person['label']
      else
        results << {
          "#{source}_id" => person['source_id'],
          "#{source}_label" => person['label']
        }
      end
    end

    results + wikidata.values
  end

  def self.dfkv
    url = 'https://github.com/dfk-paris/dfkv/raw/ng/data/DFKV_Master.xlsx'
    file = '/tmp/DFKV_Master.xlsx'
    system 'curl', '--silent', '-L', '-o', file, url

    results = []

    people = read_excel(file, "Personnes", 'id', 2)
    seen = {}
    people.each do |id, person|
      qid = person['wikidata_id']

      if qid
        next if seen[qid]
        seen[qid] = true
      end

      results << {
        'source' => 'dfkv',
        'wikidata_id' => qid,
        'source_id' => person['id'],
        'label' => person['display_name'],
        'original' => person
      }
    end

    results
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
