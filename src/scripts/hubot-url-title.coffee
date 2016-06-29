# Description:
#   Returns the title when a link is posted
#
# Configuration:
#   HUBOT_URL_TITLE_IGNORE_URLS - RegEx used to exclude Urls
#   HUBOT_URL_TITLE_IGNORE_USERS - Comma-separated list of users to ignore
#
# Commands:
#   http(s)://<site> - prints the title for site linked
#
# Author:
#   ajacksified, dentarg

jsdom      = require 'jsdom'
_          = require 'underscore'
request    = require 'request'
iconv      = require 'iconv-lite'

module.exports = (robot) ->

  ignoredusers = []
  if process.env.HUBOT_URL_TITLE_IGNORE_USERS?
    ignoredusers = process.env.HUBOT_URL_TITLE_IGNORE_USERS.split(',')

  robot.hear /(http(?:s?):\/\/(\S*))/i, (msg) ->
    url = msg.match[1]

    username = msg.message.user.name
    if _.some(ignoredusers, (user) -> user == username)
      console.log 'ignoring user due to blacklist:', username
      return

    # filter out some common files from trying
    ignore = url.match(/\.(png|jpg|jpeg|gif|txt|zip|tar\.bz|js|css)/)

    ignorePattern = process.env.HUBOT_URL_TITLE_IGNORE_URLS
    if !ignore && ignorePattern
      ignore = url.match(ignorePattern)

    unless ignore
      request(
        {url: url, encoding: null, followRedirect: false, headers: {'Accept-Language': 'ja'}}
        (error, response, body) ->
          if response.statusCode == 200
            convertBody = iconv.decode(body,'utf8')

            jsdom.env(
              convertBody
              done: (errors, window) ->
                unless errors
                  title = window.document.title.trim()
                  msg.send "/me : #{title}"
            )
      )
