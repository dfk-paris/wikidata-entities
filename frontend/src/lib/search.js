import {util} from '@wendig/lib'

let messageId = 10000
let instanceRegistry = []
let worker = null

class Search {
  constructor() {
    this.initWorker()

    instanceRegistry.push(this)

    this.resolveMap = {}
  }

  initWorker() {
    if (!this.initPromise) {
      this.initPromise = new Promise((resolve, reject) => {
        util.fetchWorker(staticUrl + '/worker.js').then(w => {
          w.onmessage = event => {
            for (const instance of instanceRegistry) {
              instance.onResponse(event)
            }
          }
          worker = w

          resolve()
        })
      })
    }

    return this.initPromise
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
    return this.initWorker().then(() => {
      const newId = messageId
      messageId += 1

      const promise = new Promise((resolve, reject) => {
        this.resolveMap[newId] = resolve

        data.messageId = newId
        worker.postMessage(data)
      })

      return promise
    })
  }
}

const search = new Search()

export default search
