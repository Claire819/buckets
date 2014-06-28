Swag = require 'swag'
_ = require 'underscore'

config = require '../config'

Entry = require '../models/entry'
Bucket = require '../models/bucket'

module.exports = (hbs) ->

  # Add Swag helpers
  Swag.registerHelpers hbs.handlebars
  hbs.registerPartials config.buckets.templatePath

  Bucket.find {}, (err, buckets) ->

    # Add the entries helper
    hbs.registerAsyncHelper 'entries', (options, cb) ->
      _.defaults options.hash,
        bucket: ''
        until: Date.now()
        since: ''
        limit: 10
        skip: 0
        sort: ''
        sort_by: 'date_posted'
        sort_dir: 'desc'
        status: 'live'
        find: ''

      searchQuery = {}
      bucketPath = path: 'bucket'

      if options.hash.bucket
        bucket = _.findWhere(buckets, slug: options.hash.bucket)
        searchQuery['bucket'] = bucket._id if bucket

      if options.hash.where
        searchQuery.$where = options.hash.where

      Entry.find(searchQuery)
        .populate('bucket')
        .populate('author')
        .limit(options.hash.limit)
        .skip(options.hash.skip)
        .exec (err, pages) ->
          console.log err if err

          return cb options.inverse @ if pages?.length is 0 or err

          ret = []
          for page in pages
            try
              ret.push options.fn page.toJSON()
            catch e
              console.log e.stack, arguments

          cb ret.join('')
