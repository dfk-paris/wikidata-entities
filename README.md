# DFK Wikidata Entities

The repository encompasses data and code for the central index of all fully named persons in the data collections (databases, text editions, catalogs) of the DFK Paris. Many of them are referenced to Wikidata Items. Each person has a unique DFK person ID and at least one ID established by the database, -the collection it stems from. Some have more than ID one from one database. This is a result of duplicates in the databases.

# Data

The data is aggregated from

* [Architrave - Kunst und Architektur in Paris und Versailles im Spiegel deutscher Reiseberichte des Barock](https://www.architrave.eu/index.html?lang=de) (lang: DE) / [Architrave - Art et architecture à Paris et Versailles dans les récits de voyageurs allemands à l’époque baroque](https://www.architrave.eu/index.html?lang=frl) (lang: FR)
* [Correspondence between Henri Fantin-Latour and Otto Scholderer, 1858-1902](https://dfk-paris.org/en/research-project/correspondence-between-henri-fantin-latour-and-otto-scholderer-1858-1902-967.html) (lang: DE) / [Briefwechsel zwischen Henri Fantin-Latour und Otto Scholderer, 1858–1902](https://dfk-paris.org/de/research-project/briefwechsel-zwischen-henri-fantin-latour-und-otto-scholderer-1858%E2%80%931902-967.html) (lang: FR)
* [Deutsch-Französische Kunstvermittlung 1870–1940 und 1945–1960](https://dfk-paris.org/de/page/deutsch-franzoesische-kunstvermittlung-1870_1940-und-1945_1960-datenbank-2391.html) (lang: DE) / [Bases de données sur la réception artistique entre l’Allemagne et la France de 1870 à 1960](https://dfk-paris.org/fr/page/franco-allemande-reception-1870_1940-et-1945_1960-bases_de_donnees-2391.html) (lang: FR)
* [OwnReality. Jedem seine Wirklichkeit](https://dfk-paris.org/de/page/ownrealitydatenbank-und-recherche-1353.html#/?q=JTdCJTIydHlwZSUyMiUzQSUyMnNvdXJjZXMlMjIlMkMlMjJwYWdlJTIyJTNBMSU3RA==) (lang: DE) / [OwnReality. À chacun son réel](https://dfk-paris.org/fr/page/ownrealityrecherche-croisee-1353.html#/?q=JTdCJTIydHlwZSUyMiUzQSUyMnNvdXJjZXMlMjIlMkMlMjJwYWdlJTIyJTNBMSU3RA==) (lang: FR) / [OwnReality. To Each His Own](https://dfk-paris.org/en/page/ownrealitydatabase-and-research-tool-1353.html#/?q=JTdCJTIydHlwZSUyMiUzQSUyMnNvdXJjZXMlMjIlMkMlMjJwYWdlJTIyJTNBMSU3RA==) (lang: ENG)
* Wissenschaftliche Bearbeitung des Palais Beauharnais [Vollständiges Inventar der Möbel, Bronzen, Gemälde und anderer Gegenstände des Palais Beauharnais](https://dfk-paris.org/de/WissenschaftlicheBearbeitungdesPalaisBeauharnais/Datenbank.html) (lang: DE)

# Development

The application consists of a small ruby data munger script a frontend to be
embedded in virtually any website (static, cms, groupware etc.). Below, we
provide basic instructions on how to get a development environment up and
running.

## Requirements

More recent versions will likely also work, here is what we used during
development

* ruby 3.0
* nodejs 14.19

## Setup

Install required libraries

    bundle install
    npm install

Once this is done, start the frontend development server
with

    npm run dev

so that the frontend is available at http://127.0.0.1:4000.

# Production

To run the application in production, run

    npm run build

and then upload the contents of the `public/` directory to a web server of your
choice. Make sure the web server sends the `Access-Control-Allow-Origin: *`
header so that other pages can load the application code and data.

Once that is done, you can integrate the app into your website. Let's say you
deployed it to https://myapp.example.com, then add the following snippets to
your page:

```html
<!DOCTYPE html>
<html>
  <head>
    ...
  </head>
  <body>
    ...
    <div is="wikidata-loading"></div>
    <div is="wikidata-entities"></div>
    ...
    <script src="https://myapp.example.com/app.js"></script>
  </body>
</html>
```

The two components `wikidata-loading` and `wikidata-entities` can be placed
anywhere in your page.

# Data

After making changes to `data/entities.txt`, which is the source of data for the
person data, run `npm run import` to convert the data to a suitable json format
that the app can consume.

There is also the command `npm run aggregate` which was used to initially import
person data from other projects. It is unlikely that this task will be useful
for anyone in the future but we mention it for completeness sake.
