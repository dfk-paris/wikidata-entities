# DFK Wikidata Entities

TODO

# Data

The data is aggregated from

* dfkv ...
* pb ...
* or ...

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
choice. 

To integrate the app into your website, ...

TODO

* npm run import (after data was changed)
* npm run index (likely not useful)

..

    npm run index

to aggregate the data from upstream sources into a json file at
`public/entries.json`. You likely don't want to run this, though. This
repository already comes with a updated aggregation. 
