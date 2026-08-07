import { dictionary } from '../../offline_source/package/index.js'
import { writeFileSync } from 'node:fs'

const vowels = new Set([
  'AA', 'AE', 'AH', 'AO', 'AW', 'AY', 'EH', 'ER', 'EY',
  'IH', 'IY', 'OW', 'OY', 'UH', 'UW',
])

const ipa = {
  AA: 'ɑ', AE: 'æ', AH: 'ʌ', AO: 'ɔ', AW: 'aʊ', AY: 'aɪ',
  B: 'b', CH: 'tʃ', D: 'd', DH: 'ð', EH: 'ɛ', ER: 'ɝ', EY: 'eɪ',
  F: 'f', G: 'ɡ', HH: 'h', IH: 'ɪ', IY: 'i', JH: 'dʒ', K: 'k',
  L: 'l', M: 'm', N: 'n', NG: 'ŋ', OW: 'oʊ', OY: 'ɔɪ', P: 'p',
  R: 'ɹ', S: 's', SH: 'ʃ', T: 't', TH: 'θ', UH: 'ʊ', UW: 'u',
  V: 'v', W: 'w', Y: 'j', Z: 'z', ZH: 'ʒ',
}

const legalOnsets = new Set([
  'B', 'CH', 'D', 'DH', 'F', 'G', 'HH', 'JH', 'K', 'L', 'M', 'N',
  'P', 'R', 'S', 'SH', 'T', 'TH', 'V', 'W', 'Y', 'Z', 'ZH',
  'P R', 'T R', 'K R', 'B R', 'D R', 'G R', 'F R', 'TH R', 'SH R',
  'S P', 'S T', 'S K', 'S M', 'S N', 'S L', 'S W',
  'P L', 'K L', 'B L', 'G L', 'F L', 'K W', 'G W', 'T W', 'D W',
  'S P R', 'S T R', 'S K R', 'S P L', 'S K W',
])

function stressStart(tokens, vowelIndex, previousVowelIndex) {
  if (previousVowelIndex < 0) return 0
  const between = tokens.slice(previousVowelIndex + 1, vowelIndex)
    .map((token) => token.replace(/\d/g, ''))
  for (let length = Math.min(3, between.length); length >= 1; length--) {
    const candidate = between.slice(-length).join(' ')
    if (legalOnsets.has(candidate)) return vowelIndex - length
  }
  return vowelIndex
}

function toIpa(pronunciation) {
  const tokens = pronunciation.split(' ')
  const markers = new Map()
  let previousVowelIndex = -1

  for (let index = 0; index < tokens.length; index++) {
    const base = tokens[index].replace(/\d/g, '')
    if (!vowels.has(base)) continue
    const stress = tokens[index].match(/[12]/)?.[0]
    if (stress) {
      markers.set(stressStart(tokens, index, previousVowelIndex),
        stress === '1' ? 'ˈ' : 'ˌ')
    }
    previousVowelIndex = index
  }

  const result = tokens.map((token, index) => {
    const base = token.replace(/\d/g, '')
    const stress = token.match(/\d/)?.[0]
    let sound = ipa[base] ?? base.toLowerCase()
    if (base === 'AH' && stress === '0') sound = 'ə'
    if (base === 'ER' && stress === '0') sound = 'ɚ'
    return `${markers.get(index) ?? ''}${sound}`
  }).join('')

  return `/${result}/`
}

const rows = Object.entries(dictionary)
  .filter(([word]) => !/\(\d+\)$/.test(word))
  .filter(([word]) => /^[a-z][a-z'.-]*$/.test(word))
  .map(([word, pronunciation]) => `${word}\t${toIpa(pronunciation)}`)
  .sort((a, b) => a.localeCompare(b))

writeFileSync('assets/cmu_ipa.tsv', `${rows.join('\n')}\n`)
console.log(`Generated ${rows.length} offline entries.`)
