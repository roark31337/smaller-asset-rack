
async = require 'async'
should = require('chai').should()
rack = require '../.'
express = require 'express'
easyrequest = require 'request'
fs = require 'fs'

describe 'an asset', ->
    app = null
    server = null

    beforeEach ->
        app = express()

    it 'should work with no hash', (done) ->
      app.use asset = new rack.Asset
            url: '/blank.txt',
            contents: 'asset-rack'
        server = app.listen 7076, ->
            easyrequest 'http://localhost:7076/blank.txt', (error, response, body) ->
                response.headers['content-type'].should.equal 'text/plain'
                should.not.exist response.headers['cache-control']
                body.should.equal 'asset-rack'
                done()

    it 'should work with hash', (done) ->
        app.use new rack.Asset
            url: '/blank.txt',
            contents: 'asset-rack'
        server = app.listen 7076, ->
            easyrequest 'http://localhost:7076/blank-8ac5a0913aa77cb8570e8f2b96e0a1e7.txt', (error, response, body) ->
                response.headers['content-type'].should.equal 'text/plain'
                response.headers['cache-control'].should.equal 'public, max-age=31536000'
                body.should.equal 'asset-rack'
                done()

    it 'should work with no hash option', (done) ->
        app.use asset = new rack.Asset
            url: '/blank.txt',
            contents: 'asset-rack'
            hash: false
        server = app.listen 7076, ->
            async.parallel [
                (next) ->
                    easyrequest 'http://localhost:7076/blank.txt', (error, response, body) ->
                        response.headers['content-type'].should.equal 'text/plain'
                        should.not.exist response.headers['cache-control']
                        body.should.equal 'asset-rack'
                        next()
                (next) ->
                    easyrequest 'http://localhost:7076/blank-8ac5a0913aa77cb8570e8f2b96e0a1e7.txt', (error, response, body) ->
                        response.statusCode.should.equal 404
                        next()
            ], done

    it 'should work with hash option', (done) ->
        app.use new rack.Asset
            url: '/blank.txt'
            contents: 'asset-rack'
            hash: true
        server = app.listen 7076, ->
            async.parallel [
                (next) ->
                    easyrequest 'http://localhost:7076/blank.txt', (error, response, body) ->
                        response.statusCode.should.equal 404
                        next()
                (next) ->
                    easyrequest 'http://localhost:7076/blank-8ac5a0913aa77cb8570e8f2b96e0a1e7.txt', (error, response, body) ->
                        response.headers['content-type'].should.equal 'text/plain'
                        response.headers['cache-control'].should.equal 'public, max-age=31536000'
                        body.should.equal 'asset-rack'
                        next()
            ], done

    it 'should set caches', (done) ->

        app.use new rack.Asset
            url: '/blank.txt'
            contents: 'asset-rack'
            maxAge: 3600
        server = app.listen 7076, ->
            async.parallel [
                (next) ->
                    easyrequest 'http://localhost:7076/blank.txt', (error, response, body) ->
                        response.headers['content-type'].should.equal 'text/plain'
                        should.not.exist response.headers['cache-control']
                        body.should.equal 'asset-rack'
                        next()
                (next) ->
                    easyrequest 'http://localhost:7076/blank-8ac5a0913aa77cb8570e8f2b96e0a1e7.txt', (error, response, body) ->
                        response.headers['content-type'].should.equal 'text/plain'
                        response.headers['cache-control'].should.equal 'public, max-age=3600'
                        body.should.equal 'asset-rack'
                        next()
            ], done

    it 'should set caches with allow no hash option', (done) ->
        app.use new rack.Asset
            url: '/blank.txt'
            contents: 'asset-rack'
            maxAge: 3600
            allowNoHashCache: true
        server = app.listen 7076, ->
            async.parallel [
                (next) ->
                    easyrequest 'http://localhost:7076/blank.txt', (error, response, body) ->
                        response.headers['content-type'].should.equal 'text/plain'
                        response.headers['cache-control'].should.equal 'public, max-age=3600'
                        body.should.equal 'asset-rack'
                        next()
                (next) ->
                    easyrequest 'http://localhost:7076/blank-8ac5a0913aa77cb8570e8f2b96e0a1e7.txt', (error, response, body) ->
                        response.headers['content-type'].should.equal 'text/plain'
                        response.headers['cache-control'].should.equal 'public, max-age=3600'
                        body.should.equal 'asset-rack'
                        next()
            ], done

    afterEach (done) -> process.nextTick ->
        server.close done
