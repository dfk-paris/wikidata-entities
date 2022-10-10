require 'csv'

require './lib/dfkv'

begin
  require 'pry'
rescue LoadError => e
end

module Wikidata

end

class Wikidata::Import
  def self.run
    csv = CSV.open('data/entities.txt',
      headers: true,
      return_headers: true,
      col_sep: '|',
      converters: [
        Proc.new{|value, field|
          if ['hide', 'deleted'].include?(field.header)
            mapping = {
              '0' => nil,
              '1' => true,
              'yes' => true,
              'true' => true,
              '' => nil,
              nil => nil
            }

            mapping[value]
          else
            value
          end
        }
      ]
    )

    dbs = headers_for(csv)[6..-1].map{|k| k.split('_')[0]}.flatten.uniq
    data = {
      'dbs' => dbs,
      'records' => {},
      'stats' => {
        'total' => {},
        'wikidata' => {}
      }
    }

    csv.each do |r|
      h = r.to_h.compact
      next if h['deleted']
      next if h['hide']

      id = h['dfk_id']

      if !data['records'][id]
        data['records'][id] = h.slice(
          'dfk_id', 'wikidata_id', 'label', 'fr_label'
        )
      end

      dbs.each do |db|
        data['records'][id]['datasets'] ||= []

        db_id = h["#{db}_id"]
        db_label = h["#{db}_label"]

        if db_id || db_label
          data['records'][id]['datasets'] << {
            'db' => db,
            'id' => db_id,
            'label' => db_label
          }

          data['stats']['total'][db] ||= 0
          data['stats']['total'][db] += 1

          if r['wikidata_id']
            data['stats']['wikidata'][db] ||= 0
            data['stats']['wikidata'][db] += 1
          end
        end
      end
    end

    data['records'] = data['records'].values

    validate!(data)
    ::Dfkv::Tasks.dump_json(data.compact, 'frontend/public/entities.json')

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

  def self.headers_for(csv)
    csv.first
    result = csv.headers
    csv.rewind
    result
  end

  def self.validate!(data)
    failed = false
    dfk_ids = {}

    data['records'].each do |record|
      id = record['dfk_id']
      dfk_ids[id] ||= 0
      dfk_ids[id] += 1

      # if dfk_ids[id] == 2
      #   puts "DFK ID #{id} has been used more than once"
      #   failed = true
      # end

      if record['datasets'].empty?
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