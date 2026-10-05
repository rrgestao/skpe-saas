
import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import './StrategicFutureWorkspace.css'

type Props={organizationId:string;formulationId:string|null;onChanged?:()=>void}
type PackageRow={id:string;status:string}
type ObjectiveRow={id:string;code:string;name:string}
type IndicatorRow={id:string;code:string;name:string;description:string|null;strategic_objective_id:string|null;formula_text:string|null;unit:string|null;polarity:string|null;measurement_frequency:string|null;data_source:string|null;baseline_value:number|null;baseline_date:string|null;status:string}
type TargetRow={id:string;indicator_id:string;target_type:string;period_start:string;period_end:string;target_value:number|null;minimum_value:number|null;challenge_value:number|null;tolerance_lower:number|null;tolerance_upper:number|null;status:string}

const emptyIndicator={id:'',objectiveId:'',code:'',name:'',description:'',formulaText:'',calculationMethod:'',unit:'%',polarity:'higher_is_better',measurementFrequency:'monthly',dataSource:'',baselineValue:'',baselineDate:'',indicatorCategory:'strategic',collectionMethod:'manual',collectionAutomatable:false}
const emptyTarget={id:'',indicatorId:'',targetType:'annual',periodStart:'',periodEnd:'',targetValue:'',minimumValue:'',challengeValue:'',toleranceLower:'',toleranceUpper:''}

function label(value:string|null|undefined){const map:Record<string,string>={draft:'Em elaboração',in_elaboration:'Em elaboração',pending_validation:'Aguardando validação',validated:'Validado',returned_for_adjustment:'Devolvido para ajustes',active:'Ativo',superseded:'Substituída'};return map[value??'']??value??'Não iniciado'}

export function StrategicIndicatorWorkspace({organizationId,formulationId,onChanged}:Props){
  const [packageRow,setPackageRow]=useState<PackageRow|null>(null)
  const [objectives,setObjectives]=useState<ObjectiveRow[]>([])
  const [indicators,setIndicators]=useState<IndicatorRow[]>([])
  const [targets,setTargets]=useState<TargetRow[]>([])
  const [canManage,setCanManage]=useState(false)
  const [canValidate,setCanValidate]=useState(false)
  const [indicatorForm,setIndicatorForm]=useState(emptyIndicator)
  const [targetForm,setTargetForm]=useState(emptyTarget)
  const [decisionNotes,setDecisionNotes]=useState('')
  const [message,setMessage]=useState('')
  const [busy,setBusy]=useState(false)

  const load=useCallback(async()=>{
    if(!formulationId)return
    const [pkg,obj,ind,tgt,manage,validate]=await Promise.all([
      supabase.from('skpe_indicator_packages').select('id,status').eq('formulation_id',formulationId).maybeSingle(),
      supabase.from('skpe_strategic_objectives').select('id,code,name').eq('formulation_id',formulationId).neq('status','archived').order('display_order'),
      supabase.from('skpe_indicators').select('id,code,name,description,strategic_objective_id,formula_text,unit,polarity,measurement_frequency,data_source,baseline_value,baseline_date,status').eq('formulation_id',formulationId).neq('status','archived').order('code'),
      supabase.from('skpe_indicator_targets').select('id,indicator_id,target_type,period_start,period_end,target_value,minimum_value,challenge_value,tolerance_lower,tolerance_upper,status').eq('formulation_id',formulationId).neq('status','superseded').order('period_start'),
      supabase.rpc('can_manage_skpe_formulation',{target_organization_id:organizationId}),
      supabase.rpc('can_validate_skpe_formulation',{target_organization_id:organizationId}),
    ])
    const error=pkg.error??obj.error??ind.error??tgt.error??manage.error??validate.error
    if(error){setMessage(error.message);return}
    setPackageRow((pkg.data??null) as PackageRow|null);setObjectives((obj.data??[]) as ObjectiveRow[]);setIndicators((ind.data??[]) as IndicatorRow[]);setTargets((tgt.data??[]) as TargetRow[]);setCanManage(Boolean(manage.data));setCanValidate(Boolean(validate.data))
  },[formulationId,organizationId])
  useEffect(()=>{void load()},[load])

  const configure=async()=>{
    if(!formulationId)return
    setBusy(true);setMessage('')
    const {error}=await supabase.rpc('configure_skpe_indicator_package',{
      p_formulation_id:formulationId,p_baseline_required:true,p_intermediate_targets_recommended:true,p_benchmark_recommended:true,
      p_automated_collection_recommended:true,p_max_indicators_per_objective:5,p_financial_concentration_threshold:60,
      p_baseline_freshness_months:24,p_metadata:{proposalOnly:true,humanValidationRequired:true,annualTargets:true},
      p_change_reason:'Configuração governada do pacote de Indicadores e Metas.'
    })
    setBusy(false);if(error){setMessage(error.message);return}
    setMessage('Pacote de Indicadores e Metas preparado em elaboração.');await load();onChanged?.()
  }

  const editIndicator=(row:IndicatorRow)=>setIndicatorForm({...emptyIndicator,id:row.id,objectiveId:row.strategic_objective_id??'',code:row.code,name:row.name,description:row.description??'',formulaText:row.formula_text??'',unit:row.unit??'%',polarity:row.polarity??'higher_is_better',measurementFrequency:row.measurement_frequency??'monthly',dataSource:row.data_source??'',baselineValue:row.baseline_value===null?'':String(row.baseline_value),baselineDate:row.baseline_date??''})

  const saveIndicator=async()=>{
    if(!formulationId)return
    if(!indicatorForm.objectiveId||!indicatorForm.code.trim()||indicatorForm.name.trim().length<3||!indicatorForm.unit.trim()){setMessage('Selecione o OE e informe código, nome e unidade do indicador.');return}
    const num=(v:string)=>v.trim()===''?null:Number(v)
    setBusy(true);setMessage('')
    const {error}=await supabase.rpc('upsert_skpe_strategic_indicator',{
      p_formulation_id:formulationId,p_code:indicatorForm.code.trim(),p_name:indicatorForm.name.trim(),p_description:indicatorForm.description.trim()||null,
      p_strategic_objective_id:indicatorForm.objectiveId,p_formula_text:indicatorForm.formulaText.trim()||null,p_calculation_method:indicatorForm.calculationMethod.trim()||null,
      p_unit:indicatorForm.unit.trim(),p_polarity:indicatorForm.polarity,p_measurement_frequency:indicatorForm.measurementFrequency,p_data_source:indicatorForm.dataSource.trim()||null,
      p_baseline_value:num(indicatorForm.baselineValue),p_baseline_date:indicatorForm.baselineDate||null,p_owner_user_id:null,p_indicator_category:indicatorForm.indicatorCategory,
      p_collection_method:indicatorForm.collectionMethod,p_collection_automatable:indicatorForm.collectionAutomatable,p_responsible_area:null,p_baseline_required_override:null,
      p_status:'draft',p_indicator_id:indicatorForm.id||null,p_metadata:{proposalOnly:true,humanValidationRequired:true},p_change_reason:indicatorForm.id?'Revisão governada de indicador estratégico.':'Inclusão governada de proposta de indicador estratégico.'
    })
    setBusy(false);if(error){setMessage(error.message);return}
    setIndicatorForm(emptyIndicator);setMessage('Indicador salvo como proposta.');await load();onChanged?.()
  }

  const editTarget=(row:TargetRow)=>setTargetForm({id:row.id,indicatorId:row.indicator_id,targetType:row.target_type,periodStart:row.period_start,periodEnd:row.period_end,targetValue:row.target_value===null?'':String(row.target_value),minimumValue:row.minimum_value===null?'':String(row.minimum_value),challengeValue:row.challenge_value===null?'':String(row.challenge_value),toleranceLower:row.tolerance_lower===null?'':String(row.tolerance_lower),toleranceUpper:row.tolerance_upper===null?'':String(row.tolerance_upper)})

  const saveTarget=async()=>{
    if(!targetForm.indicatorId||!targetForm.periodStart||!targetForm.periodEnd||targetForm.targetValue.trim()===''){setMessage('Selecione o indicador e informe período e meta.');return}
    const num=(v:string)=>v.trim()===''?null:Number(v)
    setBusy(true);setMessage('')
    const {error}=await supabase.rpc('upsert_skpe_indicator_target',{
      p_indicator_id:targetForm.indicatorId,p_target_type:targetForm.targetType,p_period_start:targetForm.periodStart,p_period_end:targetForm.periodEnd,
      p_target_value:num(targetForm.targetValue),p_minimum_value:num(targetForm.minimumValue),p_challenge_value:num(targetForm.challengeValue),
      p_tolerance_lower:num(targetForm.toleranceLower),p_tolerance_upper:num(targetForm.toleranceUpper),p_owner_user_id:null,p_status:'draft',
      p_target_id:targetForm.id||null,p_metadata:{proposalOnly:true,humanValidationRequired:true,annualized:targetForm.targetType==='annual'},
      p_change_reason:targetForm.id?'Revisão governada de meta do indicador.':'Inclusão governada de proposta de meta.'
    })
    setBusy(false);if(error){setMessage(error.message);return}
    setTargetForm(emptyTarget);setMessage('Meta salva como proposta.');await load();onChanged?.()
  }

  const transition=async(action:'submit_validation'|'validate'|'return_for_adjustments')=>{
    if(!formulationId)return
    if(action!=='submit_validation'&&decisionNotes.trim().length<10){setMessage('Registre a justificativa da decisão com pelo menos 10 caracteres.');return}
    setBusy(true);setMessage('')
    const {error}=await supabase.rpc('transition_skpe_indicator_package',{
      p_formulation_id:formulationId,p_transition_action:action,p_decision_notes:decisionNotes.trim()||null,
      p_change_reason:action==='submit_validation'?'Submissão governada de Indicadores e Metas à validação humana.':'Registro governado da decisão humana sobre Indicadores e Metas.'
    })
    setBusy(false);if(error){setMessage(error.message);return}
    setDecisionNotes('');setMessage(action==='submit_validation'?'Pacote submetido à validação humana.':action==='validate'?'Validação humana registrada.':'Pacote devolvido para ajustes.');await load();onChanged?.()
  }

  if(!formulationId)return null
  return <section className="skpe-indicator-workspace">
    <header><div><span>Área de trabalho</span><h3>Indicadores e Metas</h3><p>Defina medição, linha de base e metas sem transformar ausência de dados em números fictícios.</p></div><strong>{label(packageRow?.status)}</strong></header>
    {message?<div className="skpe-admin-message" role="status">{message}</div>:null}
    {!packageRow&&canManage?<button type="button" onClick={()=>void configure()} disabled={busy}>Preparar pacote em elaboração</button>:null}
    {packageRow?<>
      <section className="skpe-indicator-block"><h4>Indicadores</h4><div className="skpe-indicator-list">{indicators.map((row)=>{const oe=objectives.find((item)=>item.id===row.strategic_objective_id);return <article key={row.id}><div><strong>{row.code} · {row.name}</strong><span>{oe?oe.code+' · '+oe.name:'OE não associado'} · {row.unit??'sem unidade'} · {row.measurement_frequency??'sem frequência'}</span></div>{canManage&&packageRow.status!=='validated'?<button onClick={()=>editIndicator(row)}>Editar</button>:null}</article>})}</div>
      {canManage&&packageRow.status!=='validated'?<div className="skpe-indicator-grid">
        <label><span>OE *</span><select value={indicatorForm.objectiveId} onChange={(e)=>setIndicatorForm({...indicatorForm,objectiveId:e.target.value})}><option value="">Selecione</option>{objectives.map((row)=><option key={row.id} value={row.id}>{row.code} · {row.name}</option>)}</select></label>
        <label><span>Código *</span><input value={indicatorForm.code} onChange={(e)=>setIndicatorForm({...indicatorForm,code:e.target.value})}/></label>
        <label className="wide"><span>Indicador *</span><input value={indicatorForm.name} onChange={(e)=>setIndicatorForm({...indicatorForm,name:e.target.value})}/></label>
        <label className="wide"><span>Descrição</span><textarea value={indicatorForm.description} onChange={(e)=>setIndicatorForm({...indicatorForm,description:e.target.value})}/></label>
        <label className="wide"><span>Fórmula</span><input value={indicatorForm.formulaText} onChange={(e)=>setIndicatorForm({...indicatorForm,formulaText:e.target.value})}/></label>
        <label><span>Unidade *</span><input value={indicatorForm.unit} onChange={(e)=>setIndicatorForm({...indicatorForm,unit:e.target.value})}/></label>
        <label><span>Polaridade</span><select value={indicatorForm.polarity} onChange={(e)=>setIndicatorForm({...indicatorForm,polarity:e.target.value})}><option value="higher_is_better">Maior é melhor</option><option value="lower_is_better">Menor é melhor</option><option value="target_is_better">Alvo específico</option><option value="range_is_better">Faixa desejada</option></select></label>
        <label><span>Frequência</span><select value={indicatorForm.measurementFrequency} onChange={(e)=>setIndicatorForm({...indicatorForm,measurementFrequency:e.target.value})}><option value="monthly">Mensal</option><option value="quarterly">Trimestral</option><option value="semiannual">Semestral</option><option value="annual">Anual</option><option value="on_demand">Sob demanda</option></select></label>
        <label><span>Fonte de dados</span><input value={indicatorForm.dataSource} onChange={(e)=>setIndicatorForm({...indicatorForm,dataSource:e.target.value})}/></label>
        <label><span>Linha de base</span><input type="number" step="any" value={indicatorForm.baselineValue} onChange={(e)=>setIndicatorForm({...indicatorForm,baselineValue:e.target.value})}/></label>
        <label><span>Data da linha de base</span><input type="date" value={indicatorForm.baselineDate} onChange={(e)=>setIndicatorForm({...indicatorForm,baselineDate:e.target.value})}/></label>
        <div className="actions">{indicatorForm.id?<button onClick={()=>setIndicatorForm(emptyIndicator)}>Cancelar</button>:null}<button onClick={()=>void saveIndicator()} disabled={busy}>Salvar indicador</button></div>
      </div>:null}</section>

      <section className="skpe-indicator-block"><h4>Metas</h4><div className="skpe-indicator-list">{targets.map((row)=>{const ind=indicators.find((item)=>item.id===row.indicator_id);return <article key={row.id}><div><strong>{ind?.code??'Indicador'} · {row.target_type}</strong><span>{row.period_start} a {row.period_end} · meta {row.target_value??'a definir'}</span></div>{canManage&&packageRow.status!=='validated'?<button onClick={()=>editTarget(row)}>Editar</button>:null}</article>})}</div>
      {canManage&&packageRow.status!=='validated'?<div className="skpe-indicator-grid">
        <label><span>Indicador *</span><select value={targetForm.indicatorId} onChange={(e)=>setTargetForm({...targetForm,indicatorId:e.target.value})}><option value="">Selecione</option>{indicators.map((row)=><option key={row.id} value={row.id}>{row.code} · {row.name}</option>)}</select></label>
        <label><span>Tipo</span><select value={targetForm.targetType} onChange={(e)=>setTargetForm({...targetForm,targetType:e.target.value})}><option value="annual">Anual</option><option value="intermediate">Intermediária</option><option value="long_term">Longo prazo</option><option value="cycle">Ciclo</option></select></label>
        <label><span>Início *</span><input type="date" value={targetForm.periodStart} onChange={(e)=>setTargetForm({...targetForm,periodStart:e.target.value})}/></label>
        <label><span>Fim *</span><input type="date" value={targetForm.periodEnd} onChange={(e)=>setTargetForm({...targetForm,periodEnd:e.target.value})}/></label>
        <label><span>Meta *</span><input type="number" step="any" value={targetForm.targetValue} onChange={(e)=>setTargetForm({...targetForm,targetValue:e.target.value})}/></label>
        <label><span>Mínimo</span><input type="number" step="any" value={targetForm.minimumValue} onChange={(e)=>setTargetForm({...targetForm,minimumValue:e.target.value})}/></label>
        <label><span>Meta-desafio</span><input type="number" step="any" value={targetForm.challengeValue} onChange={(e)=>setTargetForm({...targetForm,challengeValue:e.target.value})}/></label>
        <label><span>Tolerância inferior</span><input type="number" step="any" value={targetForm.toleranceLower} onChange={(e)=>setTargetForm({...targetForm,toleranceLower:e.target.value})}/></label>
        <label><span>Tolerância superior</span><input type="number" step="any" value={targetForm.toleranceUpper} onChange={(e)=>setTargetForm({...targetForm,toleranceUpper:e.target.value})}/></label>
        <div className="actions">{targetForm.id?<button onClick={()=>setTargetForm(emptyTarget)}>Cancelar</button>:null}<button onClick={()=>void saveTarget()} disabled={busy}>Salvar meta</button></div>
      </div>:null}</section>

      <section className="skpe-indicator-decision"><label><span>Justificativa da decisão</span><textarea value={decisionNotes} onChange={(e)=>setDecisionNotes(e.target.value)}/></label><div>
        {canManage&&['in_elaboration','returned_for_adjustment'].includes(packageRow.status)?<button onClick={()=>void transition('submit_validation')} disabled={busy}>Submeter à validação</button>:null}
        {canValidate&&packageRow.status==='pending_validation'?<><button onClick={()=>void transition('validate')} disabled={busy}>Registrar validação</button><button onClick={()=>void transition('return_for_adjustments')} disabled={busy}>Devolver para ajustes</button></>:null}
      </div></section>
    </>:null}
  </section>
}
