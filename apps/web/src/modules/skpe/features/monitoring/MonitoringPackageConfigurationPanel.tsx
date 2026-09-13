import type { MonitoringPackageDraft } from './monitoringPackageProposal'

type OwnerOption = {
  userId: string
  name: string
}

type Props = {
  draft: MonitoringPackageDraft
  owners: OwnerOption[]
  saving: boolean
  message: string
  onChange: (patch: Partial<MonitoringPackageDraft>) => void
  onSave: () => void
}

const frequencyOptions = [
  ['monthly', 'Mensal'],
  ['quarterly', 'Trimestral'],
  ['semester', 'Semestral'],
  ['annual', 'Anual'],
  ['custom', 'Customizada'],
] as const

export function MonitoringPackageConfigurationPanel({
  draft,
  owners,
  saving,
  message,
  onChange,
  onSave,
}: Props) {
  return (
    <section className="skpe-monitoring-package-config" aria-label="Configuração governada FE-08">
      <h3>Configuração metodológica FE-08</h3>
      <p className="skpe-monitoring-empty">
        Os valores iniciais vêm dos defaults técnicos do runtime. Revise-os e defina os responsáveis antes de salvar. Salvar mantém o pacote em elaboração; não submete nem valida automaticamente.
      </p>
      <div className="skpe-monitoring-package-form-grid">
        <label><span>Frequência dos ciclos</span><select value={draft.cycleFrequency} onChange={(event) => onChange({ cycleFrequency: event.target.value })}>{frequencyOptions.map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
        <label><span>Frequência das RAEs</span><select value={draft.reviewFrequency} onChange={(event) => onChange({ reviewFrequency: event.target.value })}>{frequencyOptions.map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
        <label><span>Sobreposição de ciclos</span><select value={draft.cycleOverlapPolicy} onChange={(event) => onChange({ cycleOverlapPolicy: event.target.value })}><option value="block">Bloquear</option><option value="warn">Alertar</option><option value="allow">Permitir</option></select></label>
        <label><span>Política de agregação</span><select value={draft.aggregationPolicy} onChange={(event) => onChange({ aggregationPolicy: event.target.value })}><option value="explicit_weight">Peso explícito</option><option value="equal_weight">Peso igual</option></select></label>
        <label><span>Atualidade dos dados (dias)</span><input type="number" min={1} max={730} value={draft.dataFreshnessDays} onChange={(event) => onChange({ dataFreshnessDays: Number(event.target.value) })} /></label>
        <label><span>Tolerância de atraso (dias)</span><input type="number" min={0} max={365} value={draft.lateToleranceDays} onChange={(event) => onChange({ lateToleranceDays: Number(event.target.value) })} /></label>
        <label><span>Faixa crítica (%)</span><input type="number" min={0} max={100} value={draft.criticalThreshold} onChange={(event) => onChange({ criticalThreshold: Number(event.target.value) })} /></label>
        <label><span>Faixa de atenção (%)</span><input type="number" min={0} max={100} value={draft.attentionThreshold} onChange={(event) => onChange({ attentionThreshold: Number(event.target.value) })} /></label>
        <label><span>Faixa no caminho (%)</span><input type="number" min={0} max={100} value={draft.onTrackThreshold} onChange={(event) => onChange({ onTrackThreshold: Number(event.target.value) })} /></label>
      </div>
      <div className="skpe-monitoring-package-form-grid">
        <label><span>Responsável pelo monitoramento</span><select value={draft.ownerUserId} onChange={(event) => onChange({ ownerUserId: event.target.value })}><option value="">Selecione</option>{owners.map((owner) => <option key={owner.userId} value={owner.userId}>{owner.name}</option>)}</select></label>
        <label><span>Responsável pela governança / RAE</span><select value={draft.governanceOwnerUserId} onChange={(event) => onChange({ governanceOwnerUserId: event.target.value })}><option value="">Selecione</option>{owners.map((owner) => <option key={owner.userId} value={owner.userId}>{owner.name}</option>)}</select></label>
      </div>
      <div className="skpe-monitoring-package-checks">
        <label><input type="checkbox" checked={draft.evidenceRequired} onChange={(event) => onChange({ evidenceRequired: event.target.checked })} /> Evidência obrigatória</label>
        <label><input type="checkbox" checked={draft.dataQualityRequired} onChange={(event) => onChange({ dataQualityRequired: event.target.checked })} /> Qualidade do dado obrigatória</label>
        <label><input type="checkbox" checked={draft.confidenceRequiredForKeyResults} onChange={(event) => onChange({ confidenceRequiredForKeyResults: event.target.checked })} /> Confiança obrigatória nos KRs</label>
        <label><input type="checkbox" checked={draft.allowManualProgressOverride} onChange={(event) => onChange({ allowManualProgressOverride: event.target.checked })} /> Permitir override manual de progresso</label>
      </div>
      <label className="skpe-monitoring-package-reason"><span>Justificativa da configuração *</span><textarea value={draft.changeReason} onChange={(event) => onChange({ changeReason: event.target.value })} placeholder="Registre a motivação da configuração adotada." /></label>
      {message ? <div className="skpe-monitoring-state" role="status">{message}</div> : null}
      <div className="skpe-monitoring-package-actions"><button type="button" onClick={onSave} disabled={saving}>{saving ? 'Salvando...' : 'Salvar configuração em elaboração'}</button></div>
    </section>
  )
}
