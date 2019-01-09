import fs from 'fs'
import gulp from 'gulp'
import requestp from 'request-promise'

const BASE = './'
const SCREENDIFF_STATICS = BASE + 'screenshots/diff/mean.json'
const SCREENDIFF_TB = BASE + 'screenshots/diff/summary.png'

gulp.task('report-screendiff', async () => {
  const [{ tb }] = await Promise.all([findJSON(SCREENDIFF_STATICS)])
  process.stdout.write(`amounnt:${tb}`)
  if (tb === 0) {
    return
  }
  requestp({
    uri: 'https://slack.com/api/files.upload',
    method: 'POST',
    body: {
      token: process.env.SLACK_ACCESS_TOKEN,
      title: 'screen diff',
      filename: 'diffimage.png',
      filetype: 'auto',
      channels: process.env.SLACK_NOTIFICATION_CHANNEL_ID,
      file: fs.createReadStream(SCREENDIFF_TB)
    },
    json: true
  })
})
