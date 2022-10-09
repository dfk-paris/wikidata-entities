import DfkFrontend from '@dfk-paris/frontend'

DfkFrontend.configure({
  staticUrl: staticUrl
})

import './app.scss'

import * as riot from 'riot'
import {bus, BusRiotPlugin} from '@dfk-paris/frontend/src/lib/bus'
import {i18n, RiotPlugins} from '@wendig/lib'
import search from './lib/search'

import Loading from './components/loading.riot'
import WikidataEntities from './components/wikidata_entities.riot'
import WikidataChart from './components/chart.riot'

// import FlyIn from '@dfk-paris/dfkv/frontend/src/components/fly_in.riot'

i18n.setLocale('de')
i18n.setFallbacks(['fr', 'de', 'en'])
search.init('de')

i18n.fetch(`${DfkFrontend.config().staticUrl}/translations.json`).then(() => {

  RiotPlugins.setup(riot)
  riot.install(RiotPlugins.i18n)
  riot.install(RiotPlugins.parent)
  riot.install(RiotPlugins.setTitle)
  riot.install(BusRiotPlugin)

  riot.register('wikidata-loading', Loading)
  riot.register('wikidata-entities', WikidataEntities)
  riot.register('wikidata-chart', WikidataChart)

  riot.mount('[is]')

  console.log('mounting complete!')
})
