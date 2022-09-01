import Database from '@dfk-paris/frontend/src/lib/database'
import {util} from '@wendig/lib'

const db = new Database()
onmessage = db.handler

let storage = {}

db.action('register', (data) => {
  const results = storage.register[data.letter] || []

  return {
    letter: data.letter,
    records: results.slice(0, 20)
  }
})

const query = (data) => {
  let results = storage['records']

  const c = data.criteria
  const terms = util.fold(c['terms'])
  let ref = data.criteria['ref']
  ref = (ref ? ref.split('|') : [])
  const dfkId = data.criteria['dfkid']

  results = results.filter(record => {
    if (terms) {
      const d = util.fold(record['dfk_id'] || '')
      const dfk_id_match = !!d.match(new RegExp(terms))

      const q = util.fold(record['wikidata_id'] || '')
      const id_match = !!q.match(new RegExp(terms))

      const l = util.fold(record['label'] || '')
      const label_match = !!l.match(new RegExp(terms))

      if (!id_match && !label_match && !dfk_id_match) {
        return false
      }
    }

    for (const r of ref) {
      if (!record[`${r}_id`]) {
        return false
      }
    }

    if (dfkId) {
      if (record['dfk_id'] != dfkId) {
        return false
      }
    }

    return true
  })

  // aggregate
  let refs = {}
  let letters = {}
  for (const record of results) {
    for (const r of storage['projects']) {
      if (ref.includes(r)) {continue}

      const id = record[`${r}_id`]
      if (id) {
        refs[r] = refs[r] || 0
        refs[r] += 1
      }
    }

    const l = record['letter']
    letters[l] = letters[l] || 0
    letters[l] += 1
  }
  refs = elastify(refs)

  // filter
  results = results.filter(record => {
    if (c['letter']) {
      if (c['letter'] != record['letter']) {
        return false
      }
    }

    return true
  })


  // sort
  results = util.sortBy(results, (r) => util.fold(r['label']))


  // paginate
  const total = results.length
  const perPage = parseInt(c['per_page'] || '20')
  const page = parseInt(c['page'] || '1')
  results = results.slice((page - 1) * perPage, page * perPage)

  // consistency checks
  if (c['letter'] && !letters[c['letter']]) {
    // we are selecting for a letter that would yield no results, so we repeat
    // the search with the first letter that WOULD yield results
    data['criteria']['letter'] = Object.keys(letters)[0]
    return query(data)
  }

  const response = {
    total,
    results,
    aggs: {refs, letters}
  }
  
  console.log(response)
  return response
}
db.action('query', query)

db.action('counts', (data) => {
  return {
    wikidata: storage.wikidataCount,
    noRef: storage.records.length
  }
})

const elastify = (agg) => {
  let result = []

  for (const k of Object.keys(agg)) {
    result.push({key: k, doc_count: agg[k]})
  }

  return {
    buckets: util.sortBy(result, e => e.doc_count).reverse()
  }
}

setTimeout(() => {init()}, 0)


// functions

const init = () => {
  fetch('entities.json').then(r => r.json()).then(records => {
    storage['projects'] = collectProjects(records)
    storage['records'] = enrich(records, storage['projects'])
    storage['register'] = toRegister(storage['records'])
    storage['wikidataCount'] = countWikidata(storage['records'])

    console.log(storage)
    db.loaded()
  })
}

const collectProjects = (records) => {
  const keys = {}
  for (const r of records) {
    for (const k of Object.keys(r)) {
      keys[k] = true
    }
  }

  return Object.keys(keys).
    filter(e => e.match(/^[a-z]+_label$/)).
    map(e => e.split('_')[0])
}

const enrich = (records, projects) => {
  return records.map(record => {
    // calc label
    let labels = [
      record['label'],
      ...projects.map(e => record[`${e}_label`])
    ]

    record['label'] = labels.filter(e => e)[0]

    // compile refs
    record['refs'] = {}
    for (const k of projects) {
      const v = record[`${k}_id`]
      if (v) {
        record['refs'][k] = v
      }
    }

    // calc first letter
    record['letter'] = letterFor(record)

    return record
  })
}

const letterFor = (record) => {
  if (!record['label']) {return '?'}

  const lower = record['label'][0].toLowerCase()
  return util.fold(lower)
}

const countWikidata = (data) => {
  let result = 0

  for (const record of data) {
    if (record['wikidata_id']) {
      result += 1
    }
  }

  return result
}

const toRegister = (data) => {
  const results = {}

  for (const record of data) {
    record['label'] = 
      record['label'] ||
      record['dfkv_label'] ||
      record['or_label'] ||
      record['pb_label']

    const letter = util.fold((record['label'] || '')[0])

    results[letter] = results[letter] || []
    results[letter].push(record)
  }

  return results
}
