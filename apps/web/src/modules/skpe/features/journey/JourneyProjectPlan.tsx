import { useEffect, useMemo, useState } from 'react'

import { useNavigate } from 'react-router-dom'
import { WorkspaceTabs } from '../../../../components/design-system'

import { supabase } from '../../../../lib/supabase'
import { platformRoutes } from '../../app/skpeRoutes'
import { useSkpeWorkspace } from '../../context/SkpeWorkspaceContext'
import type { JourneyTemporalRow } from '../../contracts/journey'
import {
  loadInitiativeKanbanFilteredBoard,
  type InitiativeKanbanFilteredCardModel,
} from '../../../initiatives/kanban/initiativeKanbanFilteredBoardData'
import { JourneySchedulePlanner } from './JourneySchedulePlanner'

import './JourneyProjectPlan.css'

type ProjectPlanStage =
  | 'scope'
  | 'team'
  | 'schedule'
  | 'resources'
  | 'review'
  | 'baseline'

type StrategicProjectBinding = {
  initiative_id: string
  binding_type: string
}

type StrategicProjectInitiative = {
  id: string
  code: string
  name: string
  initiative_class: string
  status: string
  progress: number | string
  start_date: string | null
  target_end_date: string | null
  baseline_start_date: string | null
  baseline_target_end_date: string | null
}

type OperationalProjectState = {
  binding: StrategicProjectBinding | null
  initiative: StrategicProjectInitiative | null
  actions: InitiativeKanbanFilteredCardModel[]
  loading: boolean
  error: string
}
type JourneyProjectPlanProps = {
  organizationId: string
  projectId: string
  rows: JourneyTemporalRow[]
  canManageJourney: boolean
  formatDate: (value: string | null) => string
  onPlanMaterialized: () => void
}

const stages: Array<{
  id: ProjectPlanStage
  label: string
  description: string
}> = [
  {
    id: 'scope',
    label: 'Escopo',
    description: 'Estrutura metodológica do Projeto Estratégico.',
  },
  {
    id: 'team',
    label: 'Equipe e Responsabilidades',
    description: 'Quem conduz, responde, valida e participa.',
  },
  {
    id: 'schedule',
    label: 'Cronograma',
    description: 'Datas planejadas e prontidão temporal.',
  },
  {
    id: 'resources',
    label: 'Recursos',
    description: 'Capacidade e alocação necessária para executar.',
  },
  {
    id: 'review',
    label: 'Revisão',
    description: 'Checagem integrada antes do fechamento.',
  },
  {
    id: 'baseline',
    label: 'Fechar Linha de Base',
    description: 'Aprovação do plano institucional do projeto.',
  },
]

function itemTypeLabel(value: JourneyTemporalRow['item_type']) {
  const labels: Record<JourneyTemporalRow['item_type'], string> = {
    macrophase: 'MEGAFASE',
    phase: 'Fase',
    stage: 'Etapa',
    meta_stage: 'Metaetapa',
    activity: 'Atividade',
    deliverable: 'Entregável',
    gate: 'Gate',
  }

  return labels[value]
}

export function JourneyProjectPlan({
  organizationId,
  projectId,
  rows,
  canManageJourney,
  formatDate,
  onPlanMaterialized,
}: JourneyProjectPlanProps) {
  const navigate = useNavigate()
  const workspace = useSkpeWorkspace()
  const [activeStage, setActiveStage] = useState<ProjectPlanStage>('scope')
  const [operational, setOperational] = useState<OperationalProjectState>({
    binding: null,
    initiative: null,
    actions: [],
    loading: true,
    error: '',
  })

  const project = rows[0] ?? null

  useEffect(() => {
    let mounted = true

    async function loadOperationalProject() {
      setOperational((current) => ({
        ...current,
        loading: true,
        error: '',
      }))

      const bindingResponse = await supabase
        .from('skpe_project_initiative_bindings')
        .select('initiative_id, binding_type')
        .eq('organization_id', organizationId)
        .eq('skpe_project_id', projectId)
        .eq('binding_type', 'strategic_plan_implementation')
        .limit(2)

      if (!mounted) return

      if (bindingResponse.error) {
        setOperational({
          binding: null,
          initiative: null,
          actions: [],
          loading: false,
          error: `Não foi possível carregar o vínculo Jornada ↔ Projeto: ${bindingResponse.error.message}`,
        })
        return
      }

      const bindings = (bindingResponse.data ?? []) as StrategicProjectBinding[]

      if (bindings.length !== 1) {
        setOperational({
          binding: bindings[0] ?? null,
          initiative: null,
          actions: [],
          loading: false,
          error:
            bindings.length === 0
              ? 'A Jornada ainda não possui Projeto Estratégico vinculado.'
              : 'Há mais de um Projeto Estratégico vinculado à mesma Jornada.',
        })
        return
      }

      const binding = bindings[0]

      const initiativeResponse = await supabase
        .from('sparks_initiatives')
        .select(
          'id, code, name, initiative_class, status, progress, start_date, target_end_date, baseline_start_date, baseline_target_end_date',
        )
        .eq('organization_id', organizationId)
        .eq('id', binding.initiative_id)
        .is('archived_at', null)
        .maybeSingle()

      if (!mounted) return

      if (initiativeResponse.error || !initiativeResponse.data) {
        setOperational({
          binding,
          initiative: null,
          actions: [],
          loading: false,
          error: initiativeResponse.error
            ? `Não foi possível carregar o Projeto Estratégico: ${initiativeResponse.error.message}`
            : 'O vínculo existe, mas a iniciativa correspondente não foi localizada.',
        })
        return
      }

      const initiative =
        initiativeResponse.data as StrategicProjectInitiative

      try {
        const columns =
          await loadInitiativeKanbanFilteredBoard(initiative.id)

        if (!mounted) return

        setOperational({
          binding,
          initiative,
          actions: columns.flatMap((column) => column.cards),
          loading: false,
          error: '',
        })
      } catch (error) {
        if (!mounted) return

        setOperational({
          binding,
          initiative,
          actions: [],
          loading: false,
          error:
            error instanceof Error
              ? error.message
              : 'Não foi possível carregar as ações do Projeto Estratégico.',
        })
      }
    }

    void loadOperationalProject()

    return () => {
      mounted = false
    }
  }, [organizationId, projectId])

  function openStrategicProject() {
    if (!operational.initiative || !workspace.route.formulationId) return

    navigate({
      pathname: platformRoutes.skpe({
        organizationId,
        projectId,
        formulationId: workspace.route.formulationId,
        section: 'initiatives',
      }),
      search: `?initiativeId=${encodeURIComponent(
        operational.initiative.id,
      )}`,
    })
  }

  const metrics = useMemo(() => {
    const activeRows = rows.filter((row) => row.item_status !== 'cancelled')
    const topLevel = activeRows
      .filter((row) => row.parent_item_id === null)
      .sort(
        (first, second) =>
          first.display_order - second.display_order ||
          first.item_code.localeCompare(second.item_code, 'pt-BR'),
      )

    const responsibleCounts = new Map<string, number>()
    for (const row of activeRows) {
      if (!row.responsible_name) continue
      responsibleCounts.set(
        row.responsible_name,
        (responsibleCounts.get(row.responsible_name) ?? 0) + 1,
      )
    }

    const people = Array.from(responsibleCounts.entries())
      .map(([name, count]) => ({ name, count }))
      .sort(
        (first, second) =>
          second.count - first.count ||
          first.name.localeCompare(second.name, 'pt-BR'),
      )

    const operationalPeople = Array.from(
      new Set(
        operational.actions.flatMap(
          (action) => action.responsiblePersonNames,
        ),
      ),
    ).sort((first, second) =>
      first.localeCompare(second, 'pt-BR'),
    )

    return {
      activeRows,
      topLevel,
      people,
      mandatoryCount: activeRows.filter((row) => row.is_mandatory).length,
      assignedCount: activeRows.filter((row) => row.responsible_name).length,
      unassignedCount: activeRows.filter((row) => !row.responsible_name).length,
      baselineApproved: activeRows.some((row) => row.has_approved_plan),
      forecastActive: activeRows.some((row) => row.has_active_forecast),
      leafCount: activeRows.filter(
        (row) =>
          !activeRows.some((candidate) => candidate.parent_item_id === row.item_id),
      ).length,
      operationalActionCount: operational.actions.length,
      operationalRootCount: operational.actions.filter(
        (action) => action.isRoot,
      ).length,
      operationalMilestoneCount: operational.actions.filter(
        (action) => action.actionType === 'milestone',
      ).length,
      operationalPeople,
    }
  }, [rows, operational.actions])

  if (!project) return null

  return (
    <section className="skpe-project-plan">
      <header className="skpe-project-plan-hero">
        <div>
          <p className="skpe-eyebrow">Projeto Estratégico sugerido pelo SPARKs PE</p>
          <h2>{project.project_name}</h2>
          <p>
            A Jornada fornece a estrutura metodológica do Projeto Estratégico e
            organiza, de forma integrada, o escopo, as responsabilidades, o
            cronograma, os recursos, os critérios de revisão e a Linha de Base.
            O planejamento deve ser construído a partir das condições reais da
            organização, das dependências entre entregas, da capacidade
            disponível, das prioridades estratégicas e dos riscos identificados,
            evitando transformar referências de prazo em compromissos artificiais.
            Prazos de implantação, aceleração ou acompanhamento devem aparecer
            como dicas contextuais quando as iniciativas e ações forem planejadas,
            sempre sujeitos à validação da governança do projeto.
          </p>
        </div>
      </header>

      <section
        className={[
          'skpe-project-plan-binding',
          operational.error ? 'has-error' : '',
        ]
          .filter(Boolean)
          .join(' ')}
        aria-label="Vínculo Jornada Estratégica e Projeto Estratégico"
      >
        {operational.loading ? (
          <span>Carregando vínculo Jornada ↔ Projeto...</span>
        ) : operational.initiative ? (
          <>
            <div className="skpe-project-plan-binding-copy">
              <small>Projeto Estratégico vinculado</small>
              <strong>
                {operational.initiative.code} · {operational.initiative.name}
              </strong>
              <span>
                {operational.initiative.status}
                {' · '}
                {Number(operational.initiative.progress).toLocaleString(
                  'pt-BR',
                  { maximumFractionDigits: 1 },
                )}
                %
              </span>
            </div>

            <div className="skpe-project-plan-binding-actions">
              <div className="skpe-project-plan-binding-kpis">
                <span>
                  <strong>{metrics.operationalActionCount}</strong> ações/marcos
                </span>
                <span>
                  <strong>{metrics.operationalRootCount}</strong> raízes
                </span>
                <span>
                  <strong>{metrics.operationalMilestoneCount}</strong> marcos
                </span>
                <span>
                  <strong>{metrics.operationalPeople.length}</strong> pessoas
                </span>
              </div>

              <button
                type="button"
                onClick={openStrategicProject}
                disabled={!workspace.route.formulationId}
              >
                Abrir Projeto Estratégico
              </button>
            </div>
          </>
        ) : (
          <span>{operational.error}</span>
        )}
      </section>

            <WorkspaceTabs
        ariaLabel="Etapas do Plano do Projeto"
        activeId={activeStage}
        onChange={(id) => setActiveStage(id as ProjectPlanStage)}
        tabs={stages.map((stage) => ({
          id: stage.id,
          label: stage.label,
        }))}
      />

      {activeStage === 'scope' && (
        <section className="skpe-project-plan-panel">
          <div className="skpe-project-plan-panel-heading">
            <div>
              <p className="skpe-eyebrow">1 · Escopo</p>
              <h3>Estrutura metodológica e Projeto operacional</h3>
              <p>
                A Jornada permanece como fonte metodológica. A iniciativa
                vinculada materializa a execução do mesmo Projeto Estratégico,
                sem criar uma estrutura operacional concorrente.
              </p>
            </div>
            <div className="skpe-project-plan-kpis">
              <span><strong>{metrics.topLevel.length}</strong> MEGAFASES</span>
              <span><strong>{metrics.activeRows.length}</strong> itens ativos</span>
              <span><strong>{metrics.leafCount}</strong> folhas planejáveis</span>
              <span><strong>{metrics.mandatoryCount}</strong> obrigatórios</span>
              <span><strong>{metrics.operationalActionCount}</strong> materializados</span>
            </div>
          </div>

          <div className="skpe-project-scope-list">
            {metrics.topLevel.map((row) => (
              <article key={row.item_id}>
                <div>
                  <small>{itemTypeLabel(row.item_type)} · {row.item_code}</small>
                  <strong>{row.item_name}</strong>
                </div>
                <span>{row.is_mandatory ? 'Obrigatória' : 'Condicional'}</span>
              </article>
            ))}
          </div>

          <div className="skpe-project-plan-navigation">
            <span />
            <button type="button" onClick={() => setActiveStage('team')}>
              Confirmar escopo e avançar
            </button>
          </div>
        </section>
      )}

      {activeStage === 'team' && (
        <section className="skpe-project-plan-panel">
          <div className="skpe-project-plan-panel-heading">
            <div>
              <p className="skpe-eyebrow">2 · Equipe e Responsabilidades</p>
              <h3>Responsabilização do Projeto Estratégico</h3>
              <p>
                A equipe não é sinônimo de responsabilidade. O projeto pode ter
                participantes, enquanto cada item mantém sua responsabilidade
                formal governada.
              </p>
            </div>
            <div className="skpe-project-plan-kpis">
              <span><strong>{metrics.people.length}</strong> pessoas projetadas</span>
              <span><strong>{metrics.assignedCount}</strong> itens atribuídos</span>
              <span><strong>{metrics.unassignedCount}</strong> a atribuir</span>
            </div>
          </div>

          {metrics.people.length > 0 ? (
            <div className="skpe-project-team-grid">
              {metrics.people.map((person) => (
                <article key={person.name}>
                  <span className="skpe-project-team-avatar" aria-hidden="true">
                    {person.name.slice(0, 1).toUpperCase()}
                  </span>
                  <div>
                    <strong>{person.name}</strong>
                    <small>
                      {person.count} item(ns) com responsabilidade projetada
                    </small>
                  </div>
                </article>
              ))}
            </div>
          ) : (
            <div className="skpe-project-plan-callout">
              Ainda não há responsáveis projetados na Jornada.
            </div>
          )}

          <div className="skpe-project-plan-callout">
            <strong>Responsabilidades formais no Projeto:</strong>{' '}
            {metrics.operationalPeople.length > 0
              ? metrics.operationalPeople.join(', ')
              : 'ainda não materializadas nas ações.'}
          </div>

          <div className="skpe-project-plan-callout">
            A Jornada governa a responsabilidade metodológica; a iniciativa
            governa a responsabilidade operacional. O Plano do Projeto reconcilia
            as duas visões antes da Linha de Base.
          </div>

          <div className="skpe-project-plan-navigation">
            <button type="button" onClick={() => setActiveStage('scope')}>
              Voltar
            </button>
            <button type="button" onClick={() => setActiveStage('schedule')}>
              Avançar para Cronograma
            </button>
          </div>
        </section>
      )}

      {activeStage === 'schedule' && (
        <>
          <section className="skpe-project-plan-context-strip">
            <div>
              <strong>3 · Cronograma</strong>
              <span>
                Informe e revise as datas planejadas. Fases e MEGAFASES são
                consolidadas pelo backend a partir das folhas.
              </span>
            </div>
          </section>

          <JourneySchedulePlanner
            organizationId={organizationId}
            projectId={projectId}
            rows={rows}
            canManageJourney={canManageJourney}
            formatDate={formatDate}
            onPlanMaterialized={onPlanMaterialized}
          />

          <div className="skpe-project-plan-navigation">
            <button type="button" onClick={() => setActiveStage('team')}>
              Voltar
            </button>
            <button type="button" onClick={() => setActiveStage('resources')}>
              Avançar para Recursos
            </button>
          </div>
        </>
      )}

      {activeStage === 'resources' && (
        <section className="skpe-project-plan-panel">
          <div className="skpe-project-plan-panel-heading">
            <div>
              <p className="skpe-eyebrow">4 · Recursos</p>
              <h3>Capacidade necessária para executar o plano</h3>
              <p>
                Recursos humanos devem ser vinculados ao trabalho real do projeto,
                utilizando os contratos canônicos de capacidade e alocação já
                existentes no SPARKs.
              </p>
            </div>
          </div>

          <div className="skpe-project-resource-grid">
            <article>
              <strong>Equipe formal do Projeto</strong>
              <span>{metrics.operationalPeople.length} pessoa(s)</span>
              <small>
                Fonte: responsabilidades ativas das ações da iniciativa vinculada.
              </small>
            </article>
            <article>
              <strong>Capacidade quantitativa</strong>
              <span>Governada por período</span>
              <small>
                A alocação será integrada sem duplicar a fonte canônica de
                capacidade já utilizada nas Iniciativas e Ações.
              </small>
            </article>
            <article>
              <strong>Regra de fechamento</strong>
              <span>Sem inferência automática</span>
              <small>
                A Linha de Base não inventará disponibilidade de pessoas ou
                quantidade de recursos.
              </small>
            </article>
          </div>

          <div className="skpe-project-plan-navigation">
            <button type="button" onClick={() => setActiveStage('schedule')}>
              Voltar
            </button>
            <button type="button" onClick={() => setActiveStage('review')}>
              Avançar para Revisão
            </button>
          </div>
        </section>
      )}

      {activeStage === 'review' && (
        <section className="skpe-project-plan-panel">
          <div className="skpe-project-plan-panel-heading">
            <div>
              <p className="skpe-eyebrow">5 · Revisão</p>
              <h3>Revisão integrada antes da Linha de Base</h3>
              <p>
                O fechamento deve ocorrer somente após revisar a estrutura
                metodológica, responsabilidades, cronograma e recursos.
              </p>
            </div>
          </div>

          <div className="skpe-project-review-grid">
            <article>
              <span>Escopo metodológico</span>
              <strong>{metrics.activeRows.length} itens ativos</strong>
              <small>{metrics.mandatoryCount} obrigatórios</small>
            </article>
            <article>
              <span>Responsabilidades</span>
              <strong>{metrics.assignedCount} atribuídos</strong>
              <small>{metrics.unassignedCount} ainda sem responsável</small>
            </article>
            <article>
              <span>Janela inicial</span>
              <strong>{formatDate(project.project_start_date)}</strong>
              <small>
                Meta do projeto: {formatDate(project.project_target_end_date)}
              </small>
            </article>
            <article>
              <span>Plano institucional</span>
              <strong>{metrics.baselineApproved ? 'Aprovado' : 'Ainda não fechado'}</strong>
              <small>
                {metrics.forecastActive
                  ? 'Forecast operacional já ativo'
                  : 'Sem forecast operacional ativo'}
              </small>
            </article>
          </div>

          <div className="skpe-project-plan-callout">
            A prontidão temporal obrigatória é validada pelo backend no momento
            da submissão da Linha de Base. Responsabilidades e recursos serão
            progressivamente incorporados ao mesmo gate de prontidão, sem
            alterar os contratos já governados.
          </div>

          <div className="skpe-project-plan-navigation">
            <button type="button" onClick={() => setActiveStage('resources')}>
              Voltar
            </button>
            <button type="button" onClick={() => setActiveStage('baseline')}>
              Ir para Fechamento
            </button>
          </div>
        </section>
      )}

      {activeStage === 'baseline' && (
        <>
          <section className="skpe-project-plan-context-strip is-baseline">
            <div>
              <strong>6 · Fechar Linha de Base</strong>
              <span>
                A aprovação congela o plano institucional como referência. Toda
                mudança posterior deve ocorrer por Revisão da Linha de Base.
              </span>
            </div>
          </section>

          <JourneySchedulePlanner
            organizationId={organizationId}
            projectId={projectId}
            rows={rows}
            canManageJourney={canManageJourney}
            formatDate={formatDate}
            onPlanMaterialized={onPlanMaterialized}
          />

          <div className="skpe-project-plan-navigation">
            <button type="button" onClick={() => setActiveStage('review')}>
              Voltar para Revisão
            </button>
            <span />
          </div>
        </>
      )}
    </section>
  )
}