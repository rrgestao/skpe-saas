import { useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import './StrategicContentSection.css'

type Item={id:string;element_type:string;content:string;rationale:string|null;display_order:number;validation_status:string}
type Value={id:string;code:string;name:string;description:string|null;display_order:number;status:string}

const labels:Record<string,string>={
  purpose:'Propósito',mission:'Missão',vision:'Visão',
  proposito:'Propósito',missao:'Missão',visao:'Visão'
}

export function StrategicIdentitySection({organizationId}:{organizationId:string}) {
  const [items,setItems]=useState<Item[]>([])
  const [values,setValues]=useState<Value[]>([])
  const [error,setError]=useState('')
  useEffect(()=>{
    let active=true
    void Promise.all([
      supabase.from('skpe_strategic_identity_items')
        .select('id,element_type,content,rationale,display_order,validation_status')
        .eq('organization_id',organizationId).order('display_order'),
      supabase.from('skpe_strategic_values')
        .select('id,code,name,description,display_order,status')
        .eq('organization_id',organizationId).order('display_order'),
    ]).then(([a,b])=>{
      if(!active)return
      if(a.error||b.error){setError('Não foi possível carregar a Identidade Estratégica.');return}
      setItems((a.data??[]) as Item[])
      setValues((b.data??[]) as Value[])
    })
    return()=>{active=false}
  },[organizationId])

  if(error)return <section className="skpe-strategy-state is-error">{error}</section>

  return <section className="skpe-strategy-content">
    <header><span>Arquitetura Estratégica</span><h1>Identidade Estratégica</h1></header>
    <div className="skpe-strategy-identity-grid">
      {items.map(i=><article key={i.id}><small>{labels[i.element_type]??i.element_type}</small><strong>{i.content}</strong>{i.rationale?<p>{i.rationale}</p>:null}</article>)}
    </div>
    <section><h2>Valores</h2><div className="skpe-strategy-values-grid">
      {values.map(v=><article key={v.id}><small>{v.code}</small><strong>{v.name}</strong>{v.description?<p>{v.description}</p>:null}</article>)}
    </div></section>
  </section>
}