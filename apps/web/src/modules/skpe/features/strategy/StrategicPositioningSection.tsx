import { useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import './StrategicContentSection.css'

type Theme={id:string;code:string;name:string;description:string|null;display_order:number}
type Perspective={id:string;code:string;name:string;description:string|null;display_order:number}
type Objective={id:string;code:string;name:string;description:string|null;perspective_id:string|null;perspective_code:string|null}

export function StrategicPositioningSection({organizationId}:{organizationId:string}) {
  const [themes,setThemes]=useState<Theme[]>([])
  const [perspectives,setPerspectives]=useState<Perspective[]>([])
  const [objectives,setObjectives]=useState<Objective[]>([])
  const [error,setError]=useState('')
  useEffect(()=>{
    let active=true
    void Promise.all([
      supabase.from('skpe_strategic_themes').select('id,code,name,description,display_order').eq('organization_id',organizationId).order('display_order'),
      supabase.from('skpe_bsc_perspectives').select('id,code,name,description,display_order').eq('organization_id',organizationId).order('display_order'),
      supabase.from('skpe_strategic_objectives').select('id,code,name,description,perspective_id,perspective_code').eq('organization_id',organizationId).order('code'),
    ]).then(([a,b,c])=>{
      if(!active)return
      if(a.error||b.error||c.error){setError('Não foi possível carregar o Posicionamento Estratégico.');return}
      setThemes((a.data??[]) as Theme[]);setPerspectives((b.data??[]) as Perspective[]);setObjectives((c.data??[]) as Objective[])
    })
    return()=>{active=false}
  },[organizationId])

  if(error)return <section className="skpe-strategy-state is-error">{error}</section>

  return <section className="skpe-strategy-content">
    <header><span>Arquitetura Estratégica Integrada</span><h1>Posicionamento Estratégico</h1></header>
    <section><h2>{themes.length} Temas Estratégicos</h2><div className="skpe-strategy-theme-grid">
      {themes.map(t=><article key={t.id}><small>{t.code}</small><strong>{t.name}</strong>{t.description?<p>{t.description}</p>:null}</article>)}
    </div></section>
    <section><h2>{perspectives.length} Perspectivas Estratégicas</h2><div className="skpe-strategy-perspective-grid">
      {perspectives.map(p=><article key={p.id}><small>{p.code}</small><strong>{p.name}</strong>{p.description?<p>{p.description}</p>:null}
        <div className="skpe-strategy-objectives">{objectives.filter(o=>o.perspective_id===p.id||o.perspective_code===p.code).map(o=><div key={o.id}><b>{o.code}</b><span>{o.name}</span></div>)}</div>
      </article>)}
    </div></section>
    <section><h2>{objectives.length} Objetivos Estratégicos</h2></section>
  </section>
}