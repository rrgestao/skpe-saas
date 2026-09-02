import { supabase } from '../../../../lib/supabase.ts'
import type { StrategicMapPayload } from '../../contracts/strategic-map.ts'

export async function loadStrategicMap(
  formulationId: string,
): Promise<StrategicMapPayload> {
  const { data, error } = await supabase.rpc('get_skpe_strategic_map', {
    target_formulation_id: formulationId,
  })

  if (error) {
    throw new Error(`Não foi possível carregar o Mapa Estratégico: ${error.message}`)
  }

  if (!data || typeof data !== 'object') {
    throw new Error('O Mapa Estratégico retornou um payload inválido.')
  }

  return data as StrategicMapPayload
}