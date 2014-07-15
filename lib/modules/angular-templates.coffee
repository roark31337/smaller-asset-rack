fs = require 'fs'
pathutil = require 'path'
uglify = require 'uglify-js'
Asset = require('../index').Asset

readdirSyncRecursive = (rootDir, subdir) ->
  subdir = subdir or ""
  dirname = pathutil.join(rootDir, subdir)
  fileContents = fs.readdirSync(dirname)
  fileTree = []
  stats = undefined
  fileContents.forEach (fileName) ->
    stats = fs.lstatSync(pathutil.join(dirname, fileName))
    if stats.isDirectory()
      files = readdirSyncRecursive(pathutil.join(rootDir), pathutil.join(subdir, fileName))
      fileTree = fileTree.concat(files)
    else
      fileTree.push pathutil.join(subdir, fileName)
    return

  fileTree


class exports.AngularTemplatesAsset extends Asset
    mimetype: 'text/javascript'

    create: (options) ->
        options.dirname ?= options.directory # for backwards compatiblity
        @dirname = pathutil.resolve options.dirname
        @toWatch = @dirname
        @compress = options.compress or false
        @viewPrefix = options.viewPrefix or '/'
        files = readdirSyncRecursive @dirname
        templates = []

        for file in files when file.match(/\.html$/)
            template = fs.readFileSync(pathutil.join(@dirname, file), 'utf8').replace(/\\/g, '\\\\').replace(/\n/g, '\\n').replace(/'/g, '\\\'')
            templates.push "$templateCache.put('#{@viewPrefix}#{file}', '#{template}')"

        javascript = "var angularTemplates = function($templateCache) {\n#{templates.join('\n')}}"
        if options.compress is true
            @contents = uglify.minify(javascript, { fromString: true }).code
        else
            @contents = javascript
        @emit 'created'
