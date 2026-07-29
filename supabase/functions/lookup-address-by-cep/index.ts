import { corsHeaders } from 'npm:@supabase/supabase-js@^2/cors'

type LookupCepRequest = {
  cep?: string
}

type ViaCepResponse = {
  cep?: string
  logradouro?: string
  complemento?: string
  bairro?: string
  localidade?: string
  uf?: string
  ibge?: string
  gia?: string
  ddd?: string
  siafi?: string
  erro?: boolean | string
}

class CepLookupError extends Error {
  code: string
  status: number

  constructor(code: string, message: string, status: number) {
    super(message)
    this.name = 'CepLookupError'
    this.code = code
    this.status = status
  }
}

const responseHeaders = {
  ...corsHeaders,
  'Content-Type': 'application/json; charset=utf-8',
}

const jsonResponse = (
  body: Record<string, unknown>,
  status = 200,
) =>
  new Response(JSON.stringify(body), {
    status,
    headers: responseHeaders,
  })

const normalizeCep = (value: unknown) =>
  String(value ?? '').replace(/\D/g, '')

const fetchViaCep = async (cep: string) => {
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), 6000)

  try {
    const response = await fetch(
      `https://viacep.com.br/ws/${cep}/json/`,
      {
        method: 'GET',
        headers: {
          Accept: 'application/json',
          'User-Agent': 'SPARKs-Platform/1.0',
        },
        signal: controller.signal,
      },
    )

    if (!response.ok) {
      throw new CepLookupError(
        'CEP_PROVIDER_UNAVAILABLE',
        'O serviço de consulta de CEP está temporariamente indisponível.',
        503,
      )
    }

    const payload = (await response.json()) as ViaCepResponse

    if (
      payload.erro === true ||
      payload.erro === 'true' ||
      !payload.cep
    ) {
      throw new CepLookupError(
        'CEP_NOT_FOUND',
        'CEP não encontrado.',
        404,
      )
    }

    return {
      cep: normalizeCep(payload.cep),
      street: payload.logradouro?.trim() ?? '',
      district: payload.bairro?.trim() ?? '',
      city: payload.localidade?.trim() ?? '',
      stateCode: payload.uf?.trim().toUpperCase() ?? '',
      ibgeCode: payload.ibge?.trim() ?? '',
      ddd: payload.ddd?.trim() ?? '',
      provider: 'viacep',
      providerReference: `https://viacep.com.br/ws/${cep}/json/`,
    }
  } catch (error) {
    if (error instanceof CepLookupError) {
      throw error
    }

    if (error instanceof DOMException && error.name === 'AbortError') {
      throw new CepLookupError(
        'CEP_PROVIDER_TIMEOUT',
        'A consulta de CEP excedeu o tempo de resposta.',
        504,
      )
    }

    throw new CepLookupError(
      'CEP_PROVIDER_ERROR',
      'Não foi possível consultar o CEP neste momento.',
      503,
    )
  } finally {
    clearTimeout(timeoutId)
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders,
    })
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      {
        ok: false,
        code: 'METHOD_NOT_ALLOWED',
        error: 'Método não permitido.',
      },
      405,
    )
  }

  let body: LookupCepRequest

  try {
    body = (await request.json()) as LookupCepRequest
  } catch {
    return jsonResponse(
      {
        ok: false,
        code: 'INVALID_JSON',
        error: 'Corpo da requisição inválido.',
      },
      400,
    )
  }

  const cep = normalizeCep(body.cep)

  if (!/^\d{8}$/.test(cep)) {
    return jsonResponse(
      {
        ok: false,
        code: 'INVALID_CEP',
        error: 'Informe um CEP válido com oito dígitos.',
      },
      400,
    )
  }

  try {
    const address = await fetchViaCep(cep)

    return jsonResponse({
      ok: true,
      address,
    })
  } catch (error) {
    const lookupError =
      error instanceof CepLookupError
        ? error
        : new CepLookupError(
            'CEP_LOOKUP_ERROR',
            'Não foi possível consultar o CEP.',
            500,
          )

    console.error(
      JSON.stringify({
        event: 'cep_lookup_failed',
        code: lookupError.code,
        cep,
        message: lookupError.message,
      }),
    )

    return jsonResponse(
      {
        ok: false,
        code: lookupError.code,
        error: lookupError.message,
      },
      lookupError.status,
    )
  }
})