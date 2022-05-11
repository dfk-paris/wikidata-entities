require 'csv'
require 'json'

require 'bundler'
Bundler.require

module Dfk
end

module Dfk::Wikidata
  def self.run
    # pb
    # own_reality
    dfkv
  end

  def self.dfkv
    url = 'https://raw.githubusercontent.com/dfk-paris/dfkv/ng/data/DFKV_Master.xlsx'
    file = '/tmp/DFKV_Master.xlsx'
    system 'curl', '-o', file, url

    results = []

    people = read_excel(file, "Personnes")
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
        'label' => person['display_name'],
        'original' => person
      }
    end

    results
  end

  def self.own_reality
    response = Faraday.post('https://ownreality.dfkg.org/api/people', {
      terms: '*',
      per_page: 99999
    })

    binding.pry
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
        'label' => clean_label,
        'wikidata_id' => qid,
        'original' => {label => qid}
      }
    end

    results
  end

  def self.read_excel(file, sheet_name, primary_key = 'id')
    puts "reading sheet '#{sheet_name}' from '#{file}'"

    book = Roo::Spreadsheet.open(file)
    sheet = book.sheet_for(sheet_name)

    headers = sheet.row(1).map.with_index{|e, i| sheet.row(2)[i] || sheet.row(1)[i] }
    results = {}
    (3..sheet.last_row).each do |i|
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
