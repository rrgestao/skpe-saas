import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../lib/supabase'

import './EvidenceFilePreview.css'

type EvidenceFilePreviewProps = {
  storageBucket: string
  storagePath: string
  fileName: string
  mimeType?: string | null
}

type SpreadsheetSheet = {
  name: string
  rows: string[][]
}

type SlidePreview = {
  number: number
  text: string
}

type PreviewPayload =
  | { kind: 'pdf'; url: string }
  | { kind: 'image'; url: string }
  | { kind: 'text'; text: string; language: string }
  | { kind: 'spreadsheet'; sheets: SpreadsheetSheet[] }
  | { kind: 'docx'; text: string }
  | { kind: 'pptx'; slides: SlidePreview[] }
  | { kind: 'unsupported'; message: string }

const TEXT_LIMIT = 600_000
const SHEET_ROW_LIMIT = 200
const SHEET_COLUMN_LIMIT = 40

function extensionOf(fileName: string) {
  const match = fileName.toLocaleLowerCase('pt-BR').match(/\.([^.]+)$/)
  return match?.[1] ?? ''
}

function classifyFile(fileName: string, mimeType?: string | null) {
  const extension = extensionOf(fileName)
  const mime = (mimeType ?? '').toLocaleLowerCase('pt-BR')

  if (extension === 'pdf' || mime === 'application/pdf') return 'pdf'
  if (
    ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg', 'bmp'].includes(extension) ||
    mime.startsWith('image/')
  ) return 'image'
  if (['md', 'markdown', 'txt', 'csv', 'json', 'xml', 'log', 'yaml', 'yml'].includes(extension)) return 'text'
  if (['xlsx', 'xlsm'].includes(extension)) return 'spreadsheet'
  if (extension === 'docx') return 'docx'
  if (extension === 'pptx') return 'pptx'
  return 'unsupported'
}

function textLanguage(fileName: string) {
  const extension = extensionOf(fileName)
  const labels: Record<string, string> = {
    md: 'Markdown',
    markdown: 'Markdown',
    txt: 'Texto',
    csv: 'CSV',
    json: 'JSON',
    xml: 'XML',
    log: 'Log',
    yaml: 'YAML',
    yml: 'YAML',
  }
  return labels[extension] ?? 'Texto'
}

function xmlText(xml: string, paragraphTag: string, textTag: string) {
  const parser = new DOMParser()
  const document = parser.parseFromString(xml, 'application/xml')
  const paragraphs = Array.from(document.getElementsByTagName(paragraphTag))

  return paragraphs
    .map((paragraph) =>
      Array.from(paragraph.getElementsByTagName(textTag))
        .map((node) => node.textContent ?? '')
        .join(''),
    )
    .map((value) => value.trim())
    .filter(Boolean)
    .join('\n\n')
}

async function previewDocx(buffer: ArrayBuffer) {
  const { default: JSZip } = await import('jszip')
  const archive = await JSZip.loadAsync(buffer)
  const documentFile = archive.file('word/document.xml')
  if (!documentFile) throw new Error('Conteúdo principal do Word não localizado.')
  const xml = await documentFile.async('text')
  return xmlText(xml, 'w:p', 'w:t')
}

async function previewPptx(buffer: ArrayBuffer) {
  const { default: JSZip } = await import('jszip')
  const archive = await JSZip.loadAsync(buffer)
  const slideFiles = Object.keys(archive.files)
    .filter((path) => /^ppt\/slides\/slide\d+\.xml$/i.test(path))
    .sort((first, second) => {
      const firstNumber = Number(first.match(/slide(\d+)\.xml/i)?.[1] ?? 0)
      const secondNumber = Number(second.match(/slide(\d+)\.xml/i)?.[1] ?? 0)
      return firstNumber - secondNumber
    })

  const slides: SlidePreview[] = []
  for (const path of slideFiles) {
    const xml = await archive.file(path)?.async('text')
    if (!xml) continue
    const number = Number(path.match(/slide(\d+)\.xml/i)?.[1] ?? slides.length + 1)
    const parser = new DOMParser()
    const document = parser.parseFromString(xml, 'application/xml')
    const text = Array.from(document.getElementsByTagName('a:t'))
      .map((node) => node.textContent?.trim() ?? '')
      .filter(Boolean)
      .join(' · ')
    slides.push({ number, text: text || 'Slide sem texto extraível.' })
  }
  return slides
}

async function previewSpreadsheet(buffer: ArrayBuffer) {
  const ExcelJS = await import('exceljs')
  const workbook = new ExcelJS.Workbook()
  await workbook.xlsx.load(buffer)

  const sheets: SpreadsheetSheet[] = []
  workbook.eachSheet((worksheet) => {
    const rows: string[][] = []
    const maxRow = Math.min(worksheet.rowCount, SHEET_ROW_LIMIT)

    for (let rowIndex = 1; rowIndex <= maxRow; rowIndex += 1) {
      const row = worksheet.getRow(rowIndex)
      const values: string[] = []
      const maxColumn = Math.min(Math.max(row.cellCount, 1), SHEET_COLUMN_LIMIT)

      for (let columnIndex = 1; columnIndex <= maxColumn; columnIndex += 1) {
        const cell = row.getCell(columnIndex)
        values.push(cell.text ?? '')
      }
      rows.push(values)
    }

    sheets.push({ name: worksheet.name, rows })
  })

  return sheets
}

export function EvidenceFilePreview({
  storageBucket,
  storagePath,
  fileName,
  mimeType,
}: EvidenceFilePreviewProps) {
  const [payload, setPayload] = useState<PreviewPayload | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [selectedSheet, setSelectedSheet] = useState(0)

  const kind = useMemo(() => classifyFile(fileName, mimeType), [fileName, mimeType])

  useEffect(() => {
    let cancelled = false
    let objectUrl: string | null = null

    async function loadPreview() {
      setLoading(true)
      setError('')
      setPayload(null)
      setSelectedSheet(0)

      const { data, error: downloadError } = await supabase.storage
        .from(storageBucket)
        .download(storagePath)

      if (cancelled) return
      if (downloadError || !data) {
        setError(downloadError?.message ?? 'Não foi possível recuperar o arquivo para visualização.')
        setLoading(false)
        return
      }

      try {
        if (kind === 'pdf' || kind === 'image') {
          objectUrl = URL.createObjectURL(data)
          setPayload({ kind, url: objectUrl })
        } else if (kind === 'text') {
          const text = (await data.text()).slice(0, TEXT_LIMIT)
          setPayload({ kind: 'text', text, language: textLanguage(fileName) })
        } else if (kind === 'spreadsheet') {
          const sheets = await previewSpreadsheet(await data.arrayBuffer())
          setPayload({ kind: 'spreadsheet', sheets })
        } else if (kind === 'docx') {
          const text = await previewDocx(await data.arrayBuffer())
          setPayload({ kind: 'docx', text: text.slice(0, TEXT_LIMIT) })
        } else if (kind === 'pptx') {
          const slides = await previewPptx(await data.arrayBuffer())
          setPayload({ kind: 'pptx', slides })
        } else {
          setPayload({
            kind: 'unsupported',
            message: 'Este formato não possui visualização interna segura nesta versão. O arquivo permanece disponível para download.',
          })
        }
      } catch (caught) {
        if (!cancelled) {
          setError(caught instanceof Error ? caught.message : 'Não foi possível gerar a prévia do arquivo.')
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }

    void loadPreview()

    return () => {
      cancelled = true
      if (objectUrl) URL.revokeObjectURL(objectUrl)
    }
  }, [fileName, kind, storageBucket, storagePath])

  if (loading) {
    return <div className="evidence-file-preview__state">Preparando visualização...</div>
  }

  if (error) {
    return <div className="evidence-file-preview__state is-error">{error}</div>
  }

  if (!payload) return null

  if (payload.kind === 'pdf') {
    return (
      <div className="evidence-file-preview evidence-file-preview--pdf">
        <iframe src={payload.url} title={`Visualização de ${fileName}`} />
      </div>
    )
  }

  if (payload.kind === 'image') {
    return (
      <div className="evidence-file-preview evidence-file-preview--image">
        <img src={payload.url} alt={fileName} />
      </div>
    )
  }

  if (payload.kind === 'text' || payload.kind === 'docx') {
    const label = payload.kind === 'docx' ? 'Word · conteúdo textual' : payload.language
    const text = payload.text || 'O arquivo não contém texto extraível.'
    return (
      <div className="evidence-file-preview evidence-file-preview--text">
        <div className="evidence-file-preview__toolbar"><strong>{label}</strong></div>
        <pre>{text}</pre>
      </div>
    )
  }

  if (payload.kind === 'spreadsheet') {
    const sheet = payload.sheets[selectedSheet] ?? payload.sheets[0]
    return (
      <div className="evidence-file-preview evidence-file-preview--spreadsheet">
        <div className="evidence-file-preview__tabs" role="tablist" aria-label="Abas da planilha">
          {payload.sheets.map((item, index) => (
            <button
              key={item.name}
              type="button"
              className={index === selectedSheet ? 'is-active' : ''}
              onClick={() => setSelectedSheet(index)}
            >
              {item.name}
            </button>
          ))}
        </div>
        {sheet ? (
          <div className="evidence-file-preview__sheet">
            <table>
              <tbody>
                {sheet.rows.map((row, rowIndex) => (
                  <tr key={rowIndex}>
                    {row.map((cell, columnIndex) => (
                      <td key={columnIndex}>{cell}</td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="evidence-file-preview__state">A planilha não possui abas legíveis.</div>
        )}
        <small>Prévia limitada às primeiras {SHEET_ROW_LIMIT} linhas e {SHEET_COLUMN_LIMIT} colunas por aba.</small>
      </div>
    )
  }

  if (payload.kind === 'pptx') {
    return (
      <div className="evidence-file-preview evidence-file-preview--slides">
        <div className="evidence-file-preview__toolbar">
          <strong>PowerPoint · conteúdo textual dos slides</strong>
          <span>{payload.slides.length} slide(s)</span>
        </div>
        <div className="evidence-file-preview__slide-list">
          {payload.slides.map((slide) => (
            <article key={slide.number}>
              <strong>Slide {slide.number}</strong>
              <p>{slide.text}</p>
            </article>
          ))}
        </div>
      </div>
    )
  }

  return <div className="evidence-file-preview__state">{payload.message}</div>
}
