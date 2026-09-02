import { useEffect, useMemo, useState } from 'react'
import {
  Background,
  Controls,
  Handle,
  Position,
  ReactFlow,
  type NodeProps,
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'

import type { StrategicMapPayload } from '../../contracts/strategic-map.ts'
import {
  strategicMapToReactFlow,
  type StrategicMapNode,
  type StrategicMapNodeData,
} from './strategicMapAdapter.ts'
import { loadStrategicMap } from './strategicMapLoader.ts'

import './StrategicMapReadOnly.css'

type Props = {
  formulationId: string | null
}

function StrategicObjectiveNode({ data }: NodeProps<StrategicMapNode>) {
  const { objective, perspective, theme } = data as StrategicMapNodeData

  return (
    <article className="skpe-strategic-map-node">
      <Handle type="target" position={Position.Top} isConnectable={false} />
      <small>{objective.code}</small>
      <strong>{objective.title}</strong>
      <div className="skpe-strategic-map-node-context">
        {perspective ? <span>{perspective.name}</span> : null}
        {theme ? <span>{theme.name}</span> : null}
      </div>
      <Handle type="source" position={Position.Bottom} isConnectable={false} />
    </article>
  )
}

const nodeTypes = {
  strategicObjective: StrategicObjectiveNode,
}

export function StrategicMapReadOnly({ formulationId }: Props) {
  const [payload, setPayload] = useState<StrategicMapPayload | null>(null)
  const [loading, setLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    if (!formulationId) {
      setPayload(null)
      setErrorMessage('')
      setLoading(false)
      return () => {
        active = false
      }
    }

    const targetFormulationId = formulationId

    async function load() {
      setLoading(true)
      setErrorMessage('')

      try {
        const nextPayload = await loadStrategicMap(targetFormulationId)
        if (!active) return
        setPayload(nextPayload)
      } catch (error) {
        if (!active) return
        setPayload(null)
        setErrorMessage(
          error instanceof Error
            ? error.message
            : 'Não foi possível carregar o Mapa Estratégico.',
        )
      } finally {
        if (active) setLoading(false)
      }
    }

    void load()

    return () => {
      active = false
    }
  }, [formulationId])

  const graph = useMemo(() => {
    if (!payload) return { nodes: [], edges: [] }

    const mapped = strategicMapToReactFlow(payload)
    return {
      nodes: mapped.nodes.map((node) => ({
        ...node,
        draggable: false,
        connectable: false,
      })),
      edges: mapped.edges.map((edge) => ({
        ...edge,
        selectable: false,
        focusable: false,
      })),
    }
  }, [payload])

  const orderedPerspectives = useMemo(
    () =>
      [...(payload?.perspectives ?? [])].sort(
        (first, second) =>
          first.displayOrder - second.displayOrder ||
          first.code.localeCompare(second.code, 'pt-BR'),
      ),
    [payload],
  )

  const orderedThemes = useMemo(
    () =>
      [...(payload?.themes ?? [])].sort(
        (first, second) =>
          first.displayOrder - second.displayOrder ||
          first.code.localeCompare(second.code, 'pt-BR'),
      ),
    [payload],
  )

  if (!formulationId) {
    return (
      <article className="skpe-strategic-map-state">
        <h3>Mapa Estratégico</h3>
        <p>
          A visualização depende de uma versão explícita da Formulação
          Estratégica. Nenhuma versão foi inferida automaticamente.
        </p>
      </article>
    )
  }

  if (loading) {
    return (
      <article className="skpe-strategic-map-state">
        <h3>Mapa Estratégico</h3>
        <p>Carregando a arquitetura estratégica canônica.</p>
      </article>
    )
  }

  if (errorMessage) {
    return (
      <article className="skpe-strategic-map-state skpe-strategic-map-state-error">
        <h3>Mapa Estratégico</h3>
        <p>{errorMessage}</p>
      </article>
    )
  }

  if (!payload || payload.objectives.length === 0) {
    return (
      <article className="skpe-strategic-map-state">
        <h3>Mapa Estratégico</h3>
        <p>
          Nenhum Objetivo Estratégico está materializado nesta versão da
          Formulação.
        </p>
      </article>
    )
  }

  return (
    <section className="skpe-strategic-map-readonly">
      <header>
        <div>
          <small>Mapa Estratégico</small>
          <h3>Relações de causa e contribuição</h3>
        </div>
        <p>
          Visualização somente leitura. As setas exibidas correspondem
          exclusivamente às relações canônicas já registradas.
        </p>
      </header>

      <div className="skpe-strategic-map-summary">
        <span>{payload.perspectives.length} perspectiva(s)</span>
        <span>{payload.themes.length} tema(s)</span>
        <span>{payload.objectives.length} objetivo(s)</span>
        <span>{payload.relations.length} relação(ões)</span>
      </div>

      <div className="skpe-strategic-map-taxonomy">
        <section>
          <strong>Perspectivas</strong>
          <div>
            {orderedPerspectives.map((perspective) => (
              <span key={perspective.id}>
                {perspective.code} · {perspective.name}
              </span>
            ))}
          </div>
        </section>
        <section>
          <strong>Temas Estratégicos</strong>
          <div>
            {orderedThemes.map((theme) => (
              <span key={theme.id}>
                {theme.code} · {theme.name}
              </span>
            ))}
          </div>
        </section>
      </div>

      <div className="skpe-strategic-map-canvas" aria-label="Mapa Estratégico">
        <ReactFlow
          nodes={graph.nodes}
          edges={graph.edges}
          nodeTypes={nodeTypes}
          fitView
          fitViewOptions={{ padding: 0.16 }}
          nodesDraggable={false}
          nodesConnectable={false}
          elementsSelectable={false}
          panOnDrag
          zoomOnDoubleClick={false}
          deleteKeyCode={null}
        >
          <Background gap={24} size={1} />
          <Controls showInteractive={false} />
        </ReactFlow>
      </div>

      {payload.relations.length === 0 ? (
        <p className="skpe-strategic-map-empty-relations">
          Ainda não existem relações causais materializadas nesta versão.
          Nenhuma seta foi inferida pelo sistema.
        </p>
      ) : null}
    </section>
  )
}