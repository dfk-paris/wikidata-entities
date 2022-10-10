import {Database, Url, util} from '@wendig/lib'

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

  // filter (before aggs)

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

    const refIntersect = record['datasets'].
      map(e => e['db']).
      filter(e => ref.includes(e))
    if (ref.length > 0 && refIntersect.length == 0) {
      return false
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
    for (const ds of record['datasets']) {
      const db = ds['db']
      if (ref.includes(db)) {continue}

      refs[db] = refs[db] || 0
      refs[db] += 1
    }

    const l = record['letter']
    letters[l] = letters[l] || 0
    letters[l] += 1
  }
  refs = elastify(refs)


  // filter (after aggs)

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
  return {stats: storage.stats}
})

const elastify = (agg) => {
  console.log(agg, 'x')
  let result = []

  for (const k of Object.keys(agg)) {
    result.push({key: k, doc_count: agg[k]})
  }

  return {
    buckets: util.sortBy(result, e => e.doc_count).reverse()
  }
}

const init = (locale) => {
  fetch('entities.json').then(r => r.json()).then(data => {
    storage['projects'] = data['dbs']
    storage['records'] = enrich(data['records'], data['dbs'], locale)
    storage['register'] = toRegister(storage['records'])
    storage['stats'] = data['stats']

    console.log(storage)
    db.loaded()
  })
}
db.action('init', init)


// functions

const enrich = (records, dbs, locale) => {
  return records.map(record => {
    // get first valid label
    const firstDbLabel = record['datasets'].map(e => e['label']).map(e => e)[0]
    record['label'] = record['label'] || firstDbLabel

    // calculate first letter
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

const toRegister = (records) => {
  const results = {}

  for (const record of records) {
    const label = record[`label`] || ''
    const letter = util.fold(label[0])

    results[letter] = results[letter] || []
    results[letter].push(record)
  }

  return results
}
