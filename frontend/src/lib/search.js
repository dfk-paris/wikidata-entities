let messageId = 10000
let instanceRegistry = []

const worker = new Worker(staticUrl + '/worker.js', {credentials: 'same-origin'})
worker.onmessage = event => {
  for (const instance of instanceRegistry) {
    instance.onResponse(event)
  }
}

class Search {
  constructor() {
    instanceRegistry.push(this)

    this.resolveMap = {}
  }

  destruct() {
    const index = instanceRegistry.indexOf(this)
    if (index != -1) {
      instanceRegistry.splice(index, 1)
    }
  }

  onResponse(event) {
    const data = event.data

    const resolve = this.resolveMap[data.messageId]
    if (resolve) {
      delete this.resolveMap[data.messageId]
      resolve(data)
    }
  }

  counts() {
    return this.postMessage({action: 'counts'})
  }

  query(criteria) {
    return this.postMessage({action: 'query', criteria})
  }

  ready() {
    return this.postMessage({action: 'counts'})
  }

  init(locale) {
    return this.postMessage({action: 'init', locale})
  }

  postMessage(data) {
    const newId = messageId
    messageId += 1

    const promise = new Promise((resolve, reject) => {
      this.resolveMap[newId] = resolve

      data.messageId = newId
      worker.postMessage(data)
    })

    return promise
  }
}

const search = new Search()

export default search
