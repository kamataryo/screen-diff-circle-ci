#!/usr/bin/env node

// phantom.jsでスクリーンショットをとるスクリプトです。
var page = require('webpage').create()

/**
 * エラーハンドリング
 * @param  {String} msg  [description]
 * @param  {Array} trace [description]
 * @return {void}        [description]
 */
/* eslint no-undef: "off" */
phantom.onError = function(msg, trace) {
  var msgStack = ['PHANTOM ERROR: ' + msg]
  if (trace && trace.length) {
    msgStack.push('TRACE:')
    trace.forEach(function(t) {
      msgStack.push(
        ' -> ' +
          (t.file || t.sourceURL) +
          ': ' +
          t.line +
          (t.function ? ' (in function ' + t.function + ')' : '')
      )
    })
  }
  /* eslint no-console: "off" */
  console.error(msgStack.join('\n'))
  /* eslint no-undef: "off" */
  phantom.exit(1)
}

page.open('http://127.0.0.1:8080/', function() {
  window.setTimeout(function() {
    page.viewportSize = { width: 1920, height: 1080 }
    page.render('./screenshots/pc.png')
    page.viewportSize = { width: 768, height: 1080 }
    page.render('./screenshots/tb.png')
    page.viewportSize = { width: 320, height: 1080 }
    page.render('./screenshots/sp.png')
    /* eslint no-undef: "off" */
    phantom.exit()
  }, 200)
})
