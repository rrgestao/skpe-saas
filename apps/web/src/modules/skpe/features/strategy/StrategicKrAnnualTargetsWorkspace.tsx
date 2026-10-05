import { useCallback, useEffect, useMemo, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import './StrategicFutureWorkspace.css'

type KrOption = { id:string; code:string; name:string; unit:string|null }
type AnnualTargetRow = { id:string; key_result_id:string; target_year:number; target_type:'transition'|'baseline_confirmation'|'annual'; target_expression:string; target_value:number|null; comparator:string|null; unit:string|null; status:string; validation_status:string }
type Readiness = { horizonStartYear?:number|null; horizonEndYear?:number|null; expectedFullYearStart?:number|null; expectedAnnualTargets?:number; presentAnnualTargets?:number; missingAnnualTargets?:number; readyForValidation?:boolean; blockingIssueCount?:number; issues?:Array<{code?:string;severity?:string;message?:string;affectedCount?:number}> }
type Props = { formulationId:string; keyResults:KrOption[]; canManage:boolean; packageStatus:string; onChanged?:()=>void }

const emptyForm={id:'',keyResultId:'',year:'',targetType:'annual',expression:'',value:'',comparator:'textual',unit:''}

export function StrategicKrAnnualTargetsWorkspace({formulationId,keyResults,canManage,packageStatus,onChanged}:Props){
  const [rows,setRows]=useState<AnnualTargetRow[]>([])
  const [readiness,setReadiness]=useState<Readiness|null>(null)
  const [form,setForm]=useState(emptyForm)
  const [message,setMessage]=useState('')
  const [busy,setBusy]=useState(false)

  const load=useCallback(async()=>{
    const [targetsResponse,readinessResponse]=await Promise.all([
      supabase.from('skpe_key_result_annual_targets').select('id,key_result_id,target_year,target_type,target_expression,target_value,comparator,unit,status,validation_status').eq('formulation_id',formulationId).order('target_year').order('key_result_id'),
      supabase.rpc('get_skpe_key_result_annual_target_readiness',{p_formulation_id:formulationId}),
    ])
    const error=targetsResponse.error??readinessResponse.error
    if(error){setMessage(error.message);return}
    setRows((targetsResponse.data??[]) as AnnualTargetRow[])
    setReadiness((readinessResponse.data??null) as Readiness|null)
  },[formulationId])
  useEffect(()=>{void load()},[load])

  const years=useMemo(()=>{
    const start=readiness?.horizonStartYear??2026
    const end=readiness?.horizonEndYear??2030
    const values:number[]=[]
    for(let year=start;year<=end;year+=1)values.push(year)
    return values
  },[readiness?.horizonStartYear,readiness?.horizonEndYear])

  const editable=canManage&&!['validated','approved'].includes(packageStatus)

  const edit=(row:AnnualTargetRow)=>setForm({
    id:row.id,keyResultId:row.key_result_id,year:String(row.target_year),targetType:row.target_type,
    expression:row.target_expression,value:row.target_value===null?'':String(row.target_value),
    comparator:row.comparator??'textual',unit:row.unit??''
  })

  const chooseKr=(keyResultId:string)=>{
    const kr=keyResults.find((item)=>item.id===keyResultId)
    setForm((current)=>({...current,keyResultId,unit:current.unit||kr?.unit||''}))
  }

  const chooseYear=(year:string)=>{
    const isTransition=Number(year)===2026&&readiness?.horizonStartYear===2026
    setForm((current)=>({...current,year,targetType:isTransition&&current.id===''?'transition':current.targetType}))
  }

  const save=async()=>{
    if(!form.keyResultId||!form.year||!form.expression.trim()){setMessage('Selecione o Resultado-Chave, o ano e informe a expressão da meta.');return}
    const targetValue=form.value.trim()===''?null:Number(form.value)
    if(targetValue!==null&&!Number.isFinite(targetValue)){setMessage('Informe um valor numérico válido ou deixe o campo em branco.');return}
    setBusy(true);setMessage('')
    const {error}=await supabase.rpc('upsert_skpe_key_result_annual_target',{
      p_key_result_id:form.keyResultId,p_target_year:Number(form.year),p_target_type:form.targetType,
      p_target_expression:form.expression.trim(),p_target_value:targetValue,p_comparator:form.comparator||null,
      p_unit:form.unit.trim()||null,p_target_id:form.id||null,
      p_metadata:{proposalOnly:true,humanValidationRequired:true,source:'PEM-03.01'},
      p_change_reason:form.id?'Revisão governada de meta anualizada do Resultado-Chave.':'Inclusão governada de meta anualizada do Resultado-Chave.'
    })
    setBusy(false);if(error){setMessage(error.message);return}
    setForm(emptyForm)
    setMessage('Meta anual salva como proposta. Ela será validada junto com o pacote de OKRs e Resultados-Chave.')
    await load();onChanged?.()
  }

  return <section className="skpe-okr-work-block">
    <header className="skpe-strategic-readiness-header"><div>
      <p className="skpe-eyebrow">Trajetória anual dos Resultados-Chave</p>
      <h4>Metas anualizadas</h4>
      <p>As metas anuais descrevem a evolução esperada de cada Resultado-Chave ao longo do Horizonte Estratégico. Elas não são os três Ciclos de Evolução. Para a implantação iniciada com 2026 em andamento, este ano pode ser tratado como transição ou confirmação de linha de base; em regra, 2027 é o primeiro exercício anual completo de desempenho.</p>
    </div></header>
    {message?<div className="skpe-admin-message" role="status">{message}</div>:null}
    {readiness?<div className="skpe-okr-list"><article><div>
      <small>Trajetória esperada</small>
      <strong>{readiness.expectedFullYearStart??'—'} a {readiness.horizonEndYear??'—'}</strong>
      <span>{readiness.presentAnnualTargets??0} de {readiness.expectedAnnualTargets??0} metas anuais completas</span>
    </div></article></div>:null}

    <div className="skpe-okr-list">{keyResults.map((kr)=>{
      const krRows=rows.filter((row)=>row.key_result_id===kr.id).sort((a,b)=>a.target_year-b.target_year)
      return <article key={kr.id}><div>
        <strong>{kr.code} · {kr.name}</strong>
        <span>{krRows.length===0?'Trajetória anual ainda não registrada.':krRows.map((row)=>String(row.target_year)+': '+row.target_expression).join(' · ')}</span>
      </div>{editable&&krRows.length>0?<div className="actions">{krRows.map((row)=><button type="button" key={row.id} onClick={()=>edit(row)}>Editar {row.target_year}</button>)}</div>:null}</article>
    })}</div>

    {editable?<div className="skpe-okr-grid">
      <label><span>Resultado-Chave *</span><select value={form.keyResultId} onChange={(e)=>chooseKr(e.target.value)}><option value="">Selecione</option>{keyResults.map((kr)=><option value={kr.id} key={kr.id}>{kr.code} · {kr.name}</option>)}</select></label>
      <label><span>Ano *</span><select value={form.year} onChange={(e)=>chooseYear(e.target.value)}><option value="">Selecione</option>{years.map((year)=><option value={year} key={year}>{year}</option>)}</select></label>
      <label><span>Tratamento da meta</span><select value={form.targetType} onChange={(e)=>setForm({...form,targetType:e.target.value})}><option value="transition">Transição</option><option value="baseline_confirmation">Confirmação de linha de base</option><option value="annual">Meta anual</option></select></label>
      <label><span>Comparador</span><select value={form.comparator} onChange={(e)=>setForm({...form,comparator:e.target.value})}><option value="textual">Expressão textual</option><option value="eq">Igual a</option><option value="gte">Maior ou igual a</option><option value="gt">Maior que</option><option value="lte">Menor ou igual a</option><option value="lt">Menor que</option><option value="range">Faixa</option></select></label>
      <label className="wide"><span>Expressão da meta *</span><input value={form.expression} onChange={(e)=>setForm({...form,expression:e.target.value})} placeholder="Ex.: ≥ 85%; ≤ 21 dias; linha de base confirmada"/></label>
      <label><span>Valor numérico, quando aplicável</span><input type="number" step="any" value={form.value} onChange={(e)=>setForm({...form,value:e.target.value})}/></label>
      <label><span>Unidade</span><input value={form.unit} onChange={(e)=>setForm({...form,unit:e.target.value})}/></label>
      <div className="actions">{form.id?<button type="button" onClick={()=>setForm(emptyForm)}>Cancelar edição</button>:null}<button type="button" onClick={()=>void save()} disabled={busy}>{busy?'Salvando...':'Salvar meta anual'}</button></div>
    </div>:null}

    {(readiness?.issues?.length??0)>0?<div className="skpe-okr-list">{readiness?.issues?.map((issue,index)=><article key={(issue.code??'issue')+':'+index}><div><small>Pendência metodológica</small><strong>{issue.message??'Revise a trajetória anual.'}</strong>{typeof issue.affectedCount==='number'?<span>{issue.affectedCount} meta(s) pendente(s)</span>:null}</div></article>)}</div>:null}
    {rows.length>0?<small>As metas permanecem em elaboração até a validação humana do pacote de OKRs e Resultados-Chave.</small>:null}
  </section>
}