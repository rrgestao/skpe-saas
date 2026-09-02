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
  const { objective, perspective } = data as StrategicMapNodeData

  return (
    <article className="skpe-strategic-map-node">
      <Handle type="target" position={Position.Top} isConnectable={false} />
      <small>{objective.code}</small>
      <strong>{objective.title}</strong>
      {perspective ? <span>{perspective.name}</span> : null}
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
            : 'NÃ£o foi possÃ­vel carregar o Mapa EstratÃ©gico.',
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

  if (!formulationId) {
    return (
      <article className="skpe-strategic-map-state">
        <h3>Mapa EstratÃ©gico</h3>
        <p>
          A visualizaÃ§Ã£o depende de uma versÃ£o explÃ­cita da FormulaÃ§Ã£o
          EstratÃ©gica. Nenhuma versÃ£o foi inferida automaticamente.
        </p>
      </article>
    )
  }

  if (loading) {
    return (
      <article className="skpe-strategic-map-state">
        <h3>Mapa EstratÃ©gico</h3>
        <p>Carregando a arquitetura estratÃ©gica canÃ´nica.</p>
      </article>
    )
  }

  if (errorMessage) {
    return (
      <article className="skpe-strategic-map-state skpe-strategic-map-state-error">
        <h3>Mapa EstratÃ©gico</h3>
        <p>{errorMessage}</p>
      </article>
    )
  }

  if (!payload || payload.objectives.length === 0) {
    return (
      <article className="skpe-strategic-map-state">
        <h3>Mapa EstratÃ©gico</h3>
        <p>
          Nenhum Objetivo EstratÃ©gico estÃ¡ materializado nesta versÃ£o da
          FormulaÃ§Ã£o.
        </p>
      </article>
    )
  }

  return (
    <section className="skpe-strategic-map-readonly">
      <header>
        <div>
          <small>Mapa EstratÃ©gico</small>
          <h3>RelaÃ§Ãµes de causa e contribuiÃ§Ã£o</h3>
        </div>
        <p>
          VisualizaÃ§Ã£o somente leitura. As setas exibidas correspondem
          exclusivamente Ã s relaÃ§Ãµes canÃ´nicas jÃ¡ registradas.
        </p>
      </header>

      <div className="skpe-strategic-map-summary">
        <span>{payload.perspectives.length} perspectiva(s)</span>
        <span>{payload.objectives.length} objetivo(s)</span>
        <span>{payload.relations.length} relaÃ§Ã£o(Ãµes)</span>
      </div>

      <div className="skpe-strategic-map-canvas" aria-label="Mapa EstratÃ©gico">
        <ReactFlow
          nodes={graph.nodes}
          edges={graph.edges}
          nodeTypes={nodeTypes}
          fitView
          fitViewOptions={{ padding: 0.2 }}
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
          Ainda nÃ£o existem relaÃ§Ãµes causais materializadas nesta versÃ£o.
          Nenhuma seta foi inferida pelo sistema.
        </p>
      ) : null}
    </section>
  )
}