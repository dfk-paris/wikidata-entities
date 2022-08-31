require 'roo'

require './lib/dfkv'

begin
  require 'pry'
rescue LoadError => e
end

module Wikidata

end

class Wikidata::Import
  def self.run
    data = read_excel('data/entities.xlsx', 'entities')
    data = data.select{|r| !r['deleted']}
    validate!(data)
    ::Dfkv::Tasks.dump_json(data, 'frontend/public/entities.json')

    translations = 
      ::Dfkv::Tasks.read_excel('data/translations.dfkv.xlsx', "translations").
      merge(::Dfkv::Tasks.read_excel('data/translations.wikidata.xlsx', "translations"))
    app_translations = {}
    translations.each do |k, data|
      data.each do |locale, t|
        app_translations[locale] ||= {}
        app_translations[locale][k] = t
      end
    end

    ::Dfkv::Tasks.dump_json(app_translations, 'frontend/public/translations.json')
  end

  def self.read_excel(file, sheet_name)
    puts "reading sheet '#{sheet_name}' from '#{file}'"

    book = Roo::Spreadsheet.open(file)
    sheet = book.sheet_for(sheet_name)

    headers = sheet.row(1).map.with_index{|e, i| sheet.row(2)[i] || sheet.row(1)[i] }
    results = []
    (3..sheet.last_row).each do |i|
      values = sheet.row(i).map(&:to_s)
      record = headers.zip(values).to_h.reject do |k, v|
        k.nil? || v.nil? || v == ''
      end
      results << record
    end

    book.close
    results
  end

  def self.validate!(data)
    failed = false
    dfk_ids = {}

    data.each do |record|
      id = record['dfk_id']
      dfk_ids[id] ||= 0
      dfk_ids[id] += 1

      if dfk_ids[id] == 2
        puts "DFK ID #{id} has been used more than once"
        failed = true
      end

      unless (record.keys - ['dfk_id', 'wikidata_id']).any?{|k| k.to_s.match?(/^[a-z]+_id/)}
        puts "record '#{JSON.dump(record)}' isn't associated with any project"
        failed = true
      end
    end

    if failed
      puts "data not valid, stopping ..."
      exit 1
    end
  end
end