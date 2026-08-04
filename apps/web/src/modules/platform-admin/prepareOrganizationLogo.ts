export type PreparedOrganizationLogo = {
  originalFile: File
  displayFile: File
  backgroundRemoved: boolean
  processingMessage: string
}

const MAX_DIMENSION = 1800
const CORNER_SAMPLE_SIZE = 18
const COLOR_DISTANCE_THRESHOLD = 38
const FEATHER_DISTANCE = 28

function loadImage(file: File): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file)
    const image = new Image()

    image.onload = () => {
      URL.revokeObjectURL(url)
      resolve(image)
    }

    image.onerror = () => {
      URL.revokeObjectURL(url)
      reject(new Error('Não foi possível interpretar a imagem da logo.'))
    }

    image.src = url
  })
}

function canvasToBlob(canvas: HTMLCanvasElement): Promise<Blob> {
  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        if (blob) {
          resolve(blob)
          return
        }

        reject(new Error('Não foi possível gerar a versão transparente da logo.'))
      },
      'image/png',
      0.96,
    )
  })
}

function colorDistance(
  r1: number,
  g1: number,
  b1: number,
  r2: number,
  g2: number,
  b2: number,
) {
  return Math.sqrt(
    (r1 - r2) ** 2 +
      (g1 - g2) ** 2 +
      (b1 - b2) ** 2,
  )
}

function getCornerAverage(
  data: Uint8ClampedArray,
  width: number,
  height: number,
) {
  const samples: Array<[number, number, number]> = []
  const size = Math.min(CORNER_SAMPLE_SIZE, width, height)

  const regions = [
    [0, 0],
    [Math.max(0, width - size), 0],
    [0, Math.max(0, height - size)],
    [Math.max(0, width - size), Math.max(0, height - size)],
  ]

  for (const [startX, startY] of regions) {
    for (let y = startY; y < startY + size; y += 2) {
      for (let x = startX; x < startX + size; x += 2) {
        const index = (y * width + x) * 4
        samples.push([
          data[index],
          data[index + 1],
          data[index + 2],
        ])
      }
    }
  }

  const total = samples.reduce(
    (accumulator, sample) => ({
      r: accumulator.r + sample[0],
      g: accumulator.g + sample[1],
      b: accumulator.b + sample[2],
    }),
    { r: 0, g: 0, b: 0 },
  )

  return {
    r: Math.round(total.r / samples.length),
    g: Math.round(total.g / samples.length),
    b: Math.round(total.b / samples.length),
    samples,
  }
}

function hasUsefulTransparency(data: Uint8ClampedArray) {
  let transparentPixels = 0

  for (let index = 3; index < data.length; index += 4) {
    if (data[index] < 245) {
      transparentPixels += 1
    }
  }

  return transparentPixels > data.length / 4 / 250
}

function isUniformBackground(
  samples: Array<[number, number, number]>,
  background: { r: number; g: number; b: number },
) {
  const compatible = samples.filter(
    ([r, g, b]) =>
      colorDistance(
        r,
        g,
        b,
        background.r,
        background.g,
        background.b,
      ) <= COLOR_DISTANCE_THRESHOLD,
  )

  return compatible.length / samples.length >= 0.86
}

export async function prepareOrganizationLogo(
  file: File,
): Promise<PreparedOrganizationLogo> {
  if (file.type === 'image/svg+xml') {
    return {
      originalFile: file,
      displayFile: file,
      backgroundRemoved: false,
      processingMessage:
        'Logo vetorial preservada sem rasterização.',
    }
  }

  const image = await loadImage(file)
  const scale = Math.min(
    1,
    MAX_DIMENSION / Math.max(image.naturalWidth, image.naturalHeight),
  )
  const width = Math.max(1, Math.round(image.naturalWidth * scale))
  const height = Math.max(1, Math.round(image.naturalHeight * scale))

  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height

  const context = canvas.getContext('2d', {
    willReadFrequently: true,
  })

  if (!context) {
    return {
      originalFile: file,
      displayFile: file,
      backgroundRemoved: false,
      processingMessage:
        'Logo preservada porque o navegador não disponibilizou processamento gráfico.',
    }
  }

  context.drawImage(image, 0, 0, width, height)

  const imageData = context.getImageData(0, 0, width, height)

  if (hasUsefulTransparency(imageData.data)) {
    return {
      originalFile: file,
      displayFile: file,
      backgroundRemoved: false,
      processingMessage:
        'A logo já possui transparência e foi preservada.',
    }
  }

  const background = getCornerAverage(
    imageData.data,
    width,
    height,
  )

  if (!isUniformBackground(background.samples, background)) {
    return {
      originalFile: file,
      displayFile: file,
      backgroundRemoved: false,
      processingMessage:
        'O fundo não é uniforme. A logo original foi preservada para evitar perda visual.',
    }
  }

  for (let index = 0; index < imageData.data.length; index += 4) {
    const distance = colorDistance(
      imageData.data[index],
      imageData.data[index + 1],
      imageData.data[index + 2],
      background.r,
      background.g,
      background.b,
    )

    if (distance <= COLOR_DISTANCE_THRESHOLD) {
      imageData.data[index + 3] = 0
      continue
    }

    if (distance <= COLOR_DISTANCE_THRESHOLD + FEATHER_DISTANCE) {
      const ratio =
        (distance - COLOR_DISTANCE_THRESHOLD) /
        FEATHER_DISTANCE
      imageData.data[index + 3] = Math.round(255 * ratio)
    }
  }

  context.putImageData(imageData, 0, 0)

  const blob = await canvasToBlob(canvas)
  const baseName =
    file.name.replace(/\.[^.]+$/, '') || 'logo-institucional'
  const transparentFile = new File(
    [blob],
    `${baseName}-transparente.png`,
    {
      type: 'image/png',
      lastModified: Date.now(),
    },
  )

  return {
    originalFile: file,
    displayFile: transparentFile,
    backgroundRemoved: true,
    processingMessage:
      'Fundo uniforme removido automaticamente. O original também será preservado.',
  }
}