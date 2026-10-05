
import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import { StrategicKrAnnualTargetsWorkspace } from './StrategicKrAnnualTargetsWorkspace'
import './StrategicFutureWorkspace.css'

type Props = {
  organizationId: string
  formulationId: string | null
  onChanged?: () => void
}

type PackageRow = { id:string; status:string; okr_enabled:boolean }
type CycleRow = { id:string; code:string; name:string; cycle_type:string; period_start:string; period_end:string; reference_year:number|null; status:string }
type ObjectiveRow = { id:string; code:string; name:string; validation_status:string|null }
type OkrRow = { id:string; okr_cycle_id:string; code:string; title:string; description:string|null; status:string; validation_status:string; display_order:number }
type OkrObjectiveRow = { okr_id:string; strategic_objective_id:string; is_primary:boolean }
type KrRow = {
  id:string; okr_id:string; strategic_objective_id:string; code:string; name:string; description:string|null;
  baseline_value:number|null; target_value:number|null; unit:string|null; period_start:string|null; period_end:string|null;
  status:string; validation_status:string; metadata:Record<string,unknown>
}

const emptyCycle={id:'',code:'',name:'',cycleType:'annual',periodStart:'',periodEnd:'',referenceYear:''}
const emptyOkr={id:'',cycleId:'',objectiveId:'',code:'',title:'',description:'',displayOrder:100}
const emptyKr={id:'',okrId:'',objectiveId:'',code:'',name:'',definition:'',baselineValue:'',targetValue:'',unit:'%',polarity:'higher_is_better',formulaText:'',calculationMethod:'',dataSource:'',measurementFrequency:'monthly',periodStart:'',periodEnd:''}

function label(value:string|undefined|null){
  const map:Record<string,string>={draft:'Em elaboração',in_elaboration:'Em elaboração',pending_validation:'Aguardando validação',validated:'Validado',returned_for_adjustment:'Devolvido para ajustes',active:'Ativo',completed:'Concluído'}
  return map[value??'']??value??'Não iniciado'
}

export function StrategicOkrWorkspace({organizationId,formulationId,onChanged}:Props){
  const [packageRow,setPackageRow]=useState<PackageRow|null>(null)
  const [cycles,setCycles]=useState<CycleRow[]>([])
  const [objectives,setObjectives]=useState<ObjectiveRow[]>([])
  const [okrs,setOkrs]=useState<OkrRow[]>([])
  const [okrObjectives,setOkrObjectives]=useState<OkrObjectiveRow[]>([])
  const [krs,setKrs]=useState<KrRow[]>([])
  const [canManage,setCanManage]=useState(false)
  const [canValidate,setCanValidate]=useState(false)
  const [cycleForm,setCycleForm]=useState(emptyCycle)
  const [okrForm,setOkrForm]=useState(emptyOkr)
  const [krForm,setKrForm]=useState(emptyKr)
  const [decisionNotes,setDecisionNotes]=useState('')
  const [message,setMessage]=useState('')
  const [busy,setBusy]=useState(false)

  const load=useCallback(async()=>{
    if(!formulationId)return
    const [pkg,cyc,obj,okr,links,kr,manage,validate]=await Promise.all([
      supabase.from('skpe_okr_packages').select('id,status,okr_enabled').eq('formulation_id',formulationId).maybeSingle(),
      supabase.from('skpe_okr_cycles').select('id,code,name,cycle_type,period_start,period_end,reference_year,status').eq('formulation_id',formulationId).order('period_start'),
      supabase.from('skpe_strategic_objectives').select('id,code,name,validation_status').eq('formulation_id',formulationId).neq('status','archived').order('display_order'),
      supabase.from('skpe_okrs').select('id,okr_cycle_id,code,title,description,status,validation_status,display_order').eq('formulation_id',formulationId).order('display_order'),
      supabase.from('skpe_okr_objectives').select('okr_id,strategic_objective_id,is_primary').eq('formulation_id',formulationId),
      supabase.from('skpe_key_results').select('id,okr_id,strategic_objective_id,code,name,description,baseline_value,target_value,unit,period_start,period_end,status,validation_status,metadata').eq('formulation_id',formulationId).order('code'),
      supabase.rpc('can_manage_skpe_formulation',{target_organization_id:organizationId}),
      supabase.rpc('can_validate_skpe_formulation',{target_organization_id:organizationId}),
    ])
    const error=pkg.error??cyc.error??obj.error??okr.error??links.error??kr.error??manage.error??validate.error
    if(error){setMessage(error.message);return}
    setPackageRow((pkg.data??null) as PackageRow|null)
    setCycles((cyc.data??[]) as CycleRow[])
    setObjectives((obj.data??[]) as ObjectiveRow[])
    setOkrs((okr.data??[]) as OkrRow[])
    setOkrObjectives((links.data??[]) as OkrObjectiveRow[])
    setKrs((kr.data??[]) as KrRow[])
    setCanManage(Boolean(manage.data));setCanValidate(Boolean(validate.data))
  },[formulationId,organizationId])

  useEffect(()=>{void load()},[load])

  const configurePackage=async()=>{
    if(!formulationId)return
    setBusy(true);setMessage('')
    const {error}=await supabase.rpc('configure_skpe_okr_package',{
      p_formulation_id:formulationId,p_okr_enabled:true,p_okr_required_for_all_objectives:false,p_okr_cycle_required:true,
      p_minimum_key_results_per_okr:1,p_maximum_key_results_per_okr:30,p_key_result_baseline_required:true,
      p_okr_owner_required:false,p_key_result_owner_required:false,p_key_result_owner_recommended:true,
      p_key_result_weights_required:false,p_okr_alignment_enabled:true,p_automatic_progress_calculation:true,
      p_allow_manual_progress_override:false,p_cycle_overlap_policy:'warn',p_clone_progress_policy:'reset_to_baseline',
      p_metadata:{fixedKrCountRequired:false,quantityRule:'maturity_and_strategic_need',humanValidationRequired:true},
      p_change_reason:'Configuração governada do pacote de OKRs e Resultados-Chave.'
    })
    setBusy(false)
    if(error){setMessage(error.message);return}
    setMessage('Pacote de OKRs preparado em elaboração. Nenhuma proposta foi validada automaticamente.')
    await load();onChanged?.()
  }

  const saveCycle=async()=>{
    if(!formulationId)return
    if(!cycleForm.code.trim()||!cycleForm.name.trim()||!cycleForm.periodStart||!cycleForm.periodEnd){setMessage('Informe código, nome e período do ciclo.');return}
    setBusy(true);setMessage('')
    const {error}=await supabase.rpc('upsert_skpe_okr_cycle',{
      p_formulation_id:formulationId,p_code:cycleForm.code.trim(),p_name:cycleForm.name.trim(),p_description:null,
      p_cycle_type:cycleForm.cycleType,p_period_start:cycleForm.periodStart,p_period_end:cycleForm.periodEnd,
      p_reference_year:cycleForm.referenceYear?Number(cycleForm.referenceYear):null,p_owner_user_id:null,p_status:'draft',
      p_cycle_id:cycleForm.id||null,p_metadata:{proposalOnly:true,humanValidationRequired:true},
      p_change_reason:cycleForm.id?'Revisão governada do ciclo de OKR.':'Inclusão governada de ciclo de OKR.'
    })
    setBusy(false);if(error){setMessage(error.message);return}
    setCycleForm(emptyCycle);setMessage('Ciclo salvo como proposta.');await load();onChanged?.()
  }

  const editCycle=(row:CycleRow)=>setCycleForm({id:row.id,code:row.code,name:row.name,cycleType:row.cycle_type,periodStart:row.period_start,periodEnd:row.period_end,referenceYear:row.reference_year?String(row.reference_year):''})

  const saveOkr=async()=>{
    if(!formulationId)return
    if(!okrForm.cycleId||!okrForm.objectiveId||!okrForm.code.trim()||okrForm.title.trim().length<5){setMessage('Selecione ciclo e OE e informe código e objetivo qualitativo do OKR.');return}
    setBusy(true);setMessage('')
    const {data,error}=await supabase.rpc('upsert_skpe_okr',{
      p_formulation_id:formulationId,p_cycle_id:okrForm.cycleId,p_code:okrForm.code.trim(),p_title:okrForm.title.trim(),
      p_description:okrForm.description.trim()||null,p_rationale:null,p_owner_user_id:null,p_responsible_area_id:null,
      p_priority:'medium',p_status:'draft',p_display_order:okrForm.displayOrder,p_parent_okr_id:null,p_okr_id:okrForm.id||null,
      p_metadata:{proposalOnly:true,humanValidationRequired:true,objectiveQuality:'qualitative_mobilizing'},
      p_change_reason:okrForm.id?'Revisão governada de Objetivo de OKR.':'Inclusão governada de proposta de OKR.'
    })
    if(error){setBusy(false);setMessage(error.message);return}
    const savedId=String(data)
    const existingLink=okrObjectives.find((link)=>link.okr_id===savedId&&link.strategic_objective_id===okrForm.objectiveId)
    if(!existingLink){
      const linkResult=await supabase.rpc('link_skpe_okr_objective',{
        p_okr_id:savedId,p_strategic_objective_id:okrForm.objectiveId,p_contribution_weight:null,p_is_primary:true,
        p_notes:'Vínculo primário proposto entre OKR e Objetivo Estratégico.',p_change_reason:'Vínculo governado de OKR ao Objetivo Estratégico.'
      })
      if(linkResult.error){setBusy(false);setMessage(linkResult.error.message);return}
    }
    setBusy(false);setOkrForm(emptyOkr);setMessage('OKR salvo como proposta para revisão e validação.');await load();onChanged?.()
  }

  const editOkr=(row:OkrRow)=>{
    const primary=okrObjectives.find((link)=>link.okr_id===row.id&&link.is_primary)??okrObjectives.find((link)=>link.okr_id===row.id)
    setOkrForm({id:row.id,cycleId:row.okr_cycle_id,objectiveId:primary?.strategic_objective_id??'',code:row.code,title:row.title,description:row.description??'',displayOrder:row.display_order})
  }

  const saveKr=async()=>{
    if(!krForm.okrId||!krForm.objectiveId||!krForm.code.trim()||krForm.name.trim().length<5||!krForm.unit.trim()||!krForm.periodStart||!krForm.periodEnd){setMessage('Informe OKR, OE, código, Resultado-Chave, unidade e período.');return}
    setBusy(true);setMessage('')
    const numeric=(value:string)=>value.trim()===''?null:Number(value)
    const {error}=await supabase.rpc('upsert_skpe_key_result',{
      p_okr_id:krForm.okrId,p_code:krForm.code.trim(),p_name:krForm.name.trim(),p_definition:krForm.definition.trim()||null,
      p_baseline_value:numeric(krForm.baselineValue),p_target_value:numeric(krForm.targetValue),p_current_value:null,p_unit:krForm.unit.trim(),
      p_polarity:krForm.polarity,p_formula_text:krForm.formulaText.trim()||null,p_calculation_method:krForm.calculationMethod.trim()||null,
      p_data_source:krForm.dataSource.trim()||null,p_measurement_frequency:krForm.measurementFrequency,p_period_start:krForm.periodStart,p_period_end:krForm.periodEnd,
      p_owner_user_id:null,p_responsible_area_id:null,p_contribution_weight:null,p_linked_indicator_id:null,p_range_lower:null,p_range_upper:null,
      p_collection_automatable:false,p_status:'draft',p_strategic_objective_id:krForm.objectiveId,p_key_result_id:krForm.id||null,
      p_metadata:{proposalOnly:true,humanValidationRequired:true,annualizedTarget:true},p_change_reason:krForm.id?'Revisão governada de Resultado-Chave.':'Inclusão governada de proposta de Resultado-Chave.'
    })
    setBusy(false);if(error){setMessage(error.message);return}
    setKrForm(emptyKr);setMessage('Resultado-Chave salvo como proposta.');await load();onChanged?.()
  }

  const editKr=(row:KrRow)=>setKrForm({
    id:row.id,okrId:row.okr_id,objectiveId:row.strategic_objective_id,code:row.code,name:row.name,definition:row.description??'',
    baselineValue:row.baseline_value===null?'':String(row.baseline_value),targetValue:row.target_value===null?'':String(row.target_value),
    unit:row.unit??'%',polarity:String(row.metadata?.polarity??'higher_is_better'),formulaText:String(row.metadata?.formulaText??''),
    calculationMethod:String(row.metadata?.calculationMethod??''),dataSource:String(row.metadata?.dataSource??''),
    measurementFrequency:String(row.metadata?.measurementFrequency??'monthly'),periodStart:row.period_start??'',periodEnd:row.period_end??''
  })

  const transition=async(action:'submit_validation'|'validate'|'return_for_adjustments')=>{
    if(!formulationId)return
    if(action!=='submit_validation'&&decisionNotes.trim().length<10){setMessage('Registre a justificativa da decisão com pelo menos 10 caracteres.');return}
    setBusy(true);setMessage('')
    const {error}=await supabase.rpc('transition_skpe_okr_package',{
      p_formulation_id:formulationId,p_transition_action:action,p_decision_notes:decisionNotes.trim()||null,
      p_change_reason:action==='submit_validation'?'Submissão governada dos OKRs e KRs à validação humana.':'Registro governado da decisão humana sobre OKRs e KRs.'
    })
    setBusy(false);if(error){setMessage(error.message);return}
    setDecisionNotes('');setMessage(action==='submit_validation'?'Pacote submetido à validação humana.':action==='validate'?'Validação humana registrada.':'Pacote devolvido para ajustes.')
    await load();onChanged?.()
  }

  if(!formulationId)return null

  return <section className="skpe-okr-workspace">
    <header><div><span>Área de trabalho</span><h3>OKRs e Resultados-Chave</h3><p>Construa propostas mensuráveis sem copiar mecanicamente os Objetivos Estratégicos e sem impor quantidade fixa de KRs.</p></div><strong>{label(packageRow?.status)}</strong></header>
    {message?<div className="skpe-admin-message" role="status">{message}</div>:null}
    {!packageRow&&canManage?<button type="button" onClick={()=>void configurePackage()} disabled={busy}>Preparar pacote de OKRs em elaboração</button>:null}

    {packageRow?<>
      <section className="skpe-okr-work-block">
        <h4>Ciclos de OKR</h4>
        <div className="skpe-okr-list">{cycles.map((row)=><article key={row.id}><div><strong>{row.code} · {row.name}</strong><span>{row.period_start} a {row.period_end}</span></div>{canManage&&packageRow.status!=='validated'?<button onClick={()=>editCycle(row)}>Editar</button>:null}</article>)}</div>
        {canManage&&packageRow.status!=='validated'?<div className="skpe-okr-grid">
          <label><span>Código *</span><input value={cycleForm.code} onChange={(e)=>setCycleForm({...cycleForm,code:e.target.value})}/></label>
          <label><span>Nome *</span><input value={cycleForm.name} onChange={(e)=>setCycleForm({...cycleForm,name:e.target.value})}/></label>
          <label><span>Tipo</span><select value={cycleForm.cycleType} onChange={(e)=>setCycleForm({...cycleForm,cycleType:e.target.value})}><option value="annual">Anual</option><option value="semester">Semestral</option><option value="quarter">Trimestral</option><option value="custom">Customizado</option></select></label>
          <label><span>Ano de referência</span><input type="number" value={cycleForm.referenceYear} onChange={(e)=>setCycleForm({...cycleForm,referenceYear:e.target.value})}/></label>
          <label><span>Início *</span><input type="date" value={cycleForm.periodStart} onChange={(e)=>setCycleForm({...cycleForm,periodStart:e.target.value})}/></label>
          <label><span>Fim *</span><input type="date" value={cycleForm.periodEnd} onChange={(e)=>setCycleForm({...cycleForm,periodEnd:e.target.value})}/></label>
          <div className="actions">{cycleForm.id?<button onClick={()=>setCycleForm(emptyCycle)}>Cancelar</button>:null}<button onClick={()=>void saveCycle()} disabled={busy}>Salvar ciclo</button></div>
        </div>:null}
      </section>

      <section className="skpe-okr-work-block">
        <h4>Objetivos de OKR</h4>
        <div className="skpe-okr-list">{okrs.map((row)=>{const primary=okrObjectives.find((link)=>link.okr_id===row.id&&link.is_primary)??okrObjectives.find((link)=>link.okr_id===row.id);const oe=objectives.find((item)=>item.id===primary?.strategic_objective_id);return <article key={row.id}><div><small>{label(row.validation_status)}</small><strong>{row.code} · {row.title}</strong><span>{oe?oe.code+' · '+oe.name:'OE não vinculado'}</span></div>{canManage&&packageRow.status!=='validated'?<button onClick={()=>editOkr(row)}>Editar</button>:null}</article>})}</div>
        {canManage&&packageRow.status!=='validated'?<div className="skpe-okr-grid">
          <label><span>Ciclo *</span><select value={okrForm.cycleId} onChange={(e)=>setOkrForm({...okrForm,cycleId:e.target.value})}><option value="">Selecione</option>{cycles.map((row)=><option value={row.id} key={row.id}>{row.code} · {row.name}</option>)}</select></label>
          <label><span>Objetivo Estratégico *</span><select value={okrForm.objectiveId} onChange={(e)=>setOkrForm({...okrForm,objectiveId:e.target.value})}><option value="">Selecione</option>{objectives.map((row)=><option value={row.id} key={row.id}>{row.code} · {row.name}</option>)}</select></label>
          <label><span>Código *</span><input value={okrForm.code} onChange={(e)=>setOkrForm({...okrForm,code:e.target.value})}/></label>
          <label><span>Ordem</span><input type="number" value={okrForm.displayOrder} onChange={(e)=>setOkrForm({...okrForm,displayOrder:Number(e.target.value)})}/></label>
          <label className="wide"><span>Objetivo qualitativo do OKR *</span><textarea value={okrForm.title} onChange={(e)=>setOkrForm({...okrForm,title:e.target.value})}/></label>
          <label className="wide"><span>Descrição</span><textarea value={okrForm.description} onChange={(e)=>setOkrForm({...okrForm,description:e.target.value})}/></label>
          <div className="actions">{okrForm.id?<button onClick={()=>setOkrForm(emptyOkr)}>Cancelar</button>:null}<button onClick={()=>void saveOkr()} disabled={busy}>Salvar OKR</button></div>
        </div>:null}
      </section>

      <section className="skpe-okr-work-block">
        <h4>Resultados-Chave</h4>
        <div className="skpe-okr-list">{krs.map((row)=><article key={row.id}><div><small>{label(row.validation_status)}</small><strong>{row.code} · {row.name}</strong><span>{row.baseline_value??'Linha de base a apurar'} → {row.target_value??'Meta a definir'} {row.unit??''}</span></div>{canManage&&packageRow.status!=='validated'?<button onClick={()=>editKr(row)}>Editar</button>:null}</article>)}</div>
        {canManage&&packageRow.status!=='validated'?<div className="skpe-okr-grid">
          <label><span>OKR *</span><select value={krForm.okrId} onChange={(e)=>{const linked=okrObjectives.find((link)=>link.okr_id===e.target.value&&link.is_primary)??okrObjectives.find((link)=>link.okr_id===e.target.value);setKrForm({...krForm,okrId:e.target.value,objectiveId:linked?.strategic_objective_id??krForm.objectiveId})}}><option value="">Selecione</option>{okrs.map((row)=><option value={row.id} key={row.id}>{row.code} · {row.title}</option>)}</select></label>
          <label><span>OE *</span><select value={krForm.objectiveId} onChange={(e)=>setKrForm({...krForm,objectiveId:e.target.value})}><option value="">Selecione</option>{objectives.map((row)=><option value={row.id} key={row.id}>{row.code} · {row.name}</option>)}</select></label>
          <label><span>Código *</span><input value={krForm.code} onChange={(e)=>setKrForm({...krForm,code:e.target.value})}/></label>
          <label><span>Unidade *</span><input value={krForm.unit} onChange={(e)=>setKrForm({...krForm,unit:e.target.value})}/></label>
          <label className="wide"><span>Resultado-Chave *</span><textarea value={krForm.name} onChange={(e)=>setKrForm({...krForm,name:e.target.value})}/></label>
          <label className="wide"><span>Definição</span><textarea value={krForm.definition} onChange={(e)=>setKrForm({...krForm,definition:e.target.value})}/></label>
          <label><span>Linha de base</span><input type="number" step="any" value={krForm.baselineValue} onChange={(e)=>setKrForm({...krForm,baselineValue:e.target.value})}/></label>
          <label><span>Meta</span><input type="number" step="any" value={krForm.targetValue} onChange={(e)=>setKrForm({...krForm,targetValue:e.target.value})}/></label>
          <label><span>Polaridade</span><select value={krForm.polarity} onChange={(e)=>setKrForm({...krForm,polarity:e.target.value})}><option value="higher_is_better">Maior é melhor</option><option value="lower_is_better">Menor é melhor</option><option value="target_is_better">Alvo específico</option><option value="range_is_better">Faixa desejada</option></select></label>
          <label><span>Frequência</span><select value={krForm.measurementFrequency} onChange={(e)=>setKrForm({...krForm,measurementFrequency:e.target.value})}><option value="monthly">Mensal</option><option value="quarterly">Trimestral</option><option value="semiannual">Semestral</option><option value="annual">Anual</option><option value="on_demand">Sob demanda</option></select></label>
          <label><span>Início *</span><input type="date" value={krForm.periodStart} onChange={(e)=>setKrForm({...krForm,periodStart:e.target.value})}/></label>
          <label><span>Fim *</span><input type="date" value={krForm.periodEnd} onChange={(e)=>setKrForm({...krForm,periodEnd:e.target.value})}/></label>
          <label className="wide"><span>Fórmula</span><input value={krForm.formulaText} onChange={(e)=>setKrForm({...krForm,formulaText:e.target.value})}/></label>
          <label><span>Método de cálculo</span><input value={krForm.calculationMethod} onChange={(e)=>setKrForm({...krForm,calculationMethod:e.target.value})}/></label>
          <label><span>Fonte de dados</span><input value={krForm.dataSource} onChange={(e)=>setKrForm({...krForm,dataSource:e.target.value})}/></label>
          <div className="actions">{krForm.id?<button onClick={()=>setKrForm(emptyKr)}>Cancelar</button>:null}<button onClick={()=>void saveKr()} disabled={busy}>Salvar Resultado-Chave</button></div>
        </div>:null}
      </section>

      <StrategicKrAnnualTargetsWorkspace formulationId={formulationId} keyResults={krs.map((row)=>({id:row.id,code:row.code,name:row.name,unit:row.unit}))} canManage={canManage} packageStatus={packageRow.status} onChanged={onChanged} />

      <section className="skpe-okr-decision"><label><span>Justificativa da decisão</span><textarea value={decisionNotes} onChange={(e)=>setDecisionNotes(e.target.value)}/></label><div>
        {canManage&&['in_elaboration','returned_for_adjustment'].includes(packageRow.status)?<button onClick={()=>void transition('submit_validation')} disabled={busy}>Submeter à validação</button>:null}
        {canValidate&&packageRow.status==='pending_validation'?<><button onClick={()=>void transition('validate')} disabled={busy}>Registrar validação</button><button onClick={()=>void transition('return_for_adjustments')} disabled={busy}>Devolver para ajustes</button></>:null}
      </div></section>
    </>:null}
  </section>
}
