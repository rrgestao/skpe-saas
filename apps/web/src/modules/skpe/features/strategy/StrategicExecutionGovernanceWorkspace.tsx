
import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import { MonitoringPackageConfigurationPanel } from '../monitoring/MonitoringPackageConfigurationPanel'
import { MonitoringPackageWorkflowPanel } from '../monitoring/MonitoringPackageWorkflowPanel'
import {
  createInitialMonitoringPackageDraft,
  monitoringPackageDraftIsMaterializable,
  type MonitoringPackageDraft,
} from '../monitoring/monitoringPackageProposal'

type Props={organizationId:string;formulationId:string|null;onChanged?:()=>void}
type Readiness={packageStatus:string|null;readyForValidation:boolean;readyForFormulation:boolean;blockingIssues?:Array<{code:string;message:string}>}
type PackageRow={
  cycle_frequency:string;review_frequency:string;cycle_overlap_policy:string;evidence_required:boolean;data_quality_required:boolean;
  confidence_required_for_key_results:boolean;allow_manual_progress_override:boolean;data_freshness_days:number;late_tolerance_days:number;
  aggregation_policy:string;critical_threshold:number;attention_threshold:number;on_track_threshold:number;owner_user_id:string|null;governance_owner_user_id:string|null
}
type Owner={userId:string;name:string}

export function StrategicExecutionGovernanceWorkspace({organizationId,formulationId,onChanged}:Props){
  const [draft,setDraft]=useState<MonitoringPackageDraft>(createInitialMonitoringPackageDraft())
  const [owners,setOwners]=useState<Owner[]>([])
  const [readiness,setReadiness]=useState<Readiness|null>(null)
  const [canManage,setCanManage]=useState(false)
  const [canValidate,setCanValidate]=useState(false)
  const [saving,setSaving]=useState(false)
  const [transitioning,setTransitioning]=useState(false)
  const [saveMessage,setSaveMessage]=useState('')
  const [workflowMessage,setWorkflowMessage]=useState('')

  const load=useCallback(async()=>{
    if(!formulationId)return
    const [readinessResponse,peopleResponse,packageResponse,manageResponse,validateResponse]=await Promise.all([
      supabase.rpc('get_skpe_monitoring_package_readiness',{p_formulation_id:formulationId,p_include_package_state:true}),
      supabase.rpc('get_skpe_governance_people',{target_organization_id:organizationId}),
      supabase.from('skpe_monitoring_packages').select('cycle_frequency,review_frequency,cycle_overlap_policy,evidence_required,data_quality_required,confidence_required_for_key_results,allow_manual_progress_override,data_freshness_days,late_tolerance_days,aggregation_policy,critical_threshold,attention_threshold,on_track_threshold,owner_user_id,governance_owner_user_id').eq('formulation_id',formulationId).maybeSingle(),
      supabase.rpc('can_manage_skpe_formulation',{target_organization_id:organizationId}),
      supabase.rpc('can_validate_skpe_formulation',{target_organization_id:organizationId}),
    ])
    const error=readinessResponse.error??peopleResponse.error??packageResponse.error??manageResponse.error??validateResponse.error
    if(error){setSaveMessage(error.message);return}
    setReadiness((readinessResponse.data??null) as Readiness|null)
    setCanManage(Boolean(manageResponse.data));setCanValidate(Boolean(validateResponse.data))

    const governancePeople=(peopleResponse.data??[]) as Array<{person_id:string;full_name:string;preferred_name:string|null}>
    const personIds=governancePeople.map((p)=>p.person_id)
    if(personIds.length){
      const {data:profiles}=await supabase.from('sparks_people').select('id,profile_user_id').in('id',personIds).not('profile_user_id','is',null)
      const userByPerson=new Map(((profiles??[]) as Array<{id:string;profile_user_id:string|null}>).filter((p)=>p.profile_user_id).map((p)=>[p.id,p.profile_user_id as string]))
      setOwners(governancePeople.flatMap((person)=>{const userId=userByPerson.get(person.person_id);return userId?[{userId,name:person.preferred_name?.trim()||person.full_name}]:[]}))
    }else setOwners([])

    if(packageResponse.data){
      const row=packageResponse.data as PackageRow
      setDraft((current)=>({...current,cycleFrequency:row.cycle_frequency,reviewFrequency:row.review_frequency,cycleOverlapPolicy:row.cycle_overlap_policy,evidenceRequired:row.evidence_required,dataQualityRequired:row.data_quality_required,confidenceRequiredForKeyResults:row.confidence_required_for_key_results,allowManualProgressOverride:row.allow_manual_progress_override,dataFreshnessDays:row.data_freshness_days,lateToleranceDays:row.late_tolerance_days,aggregationPolicy:row.aggregation_policy,criticalThreshold:row.critical_threshold,attentionThreshold:row.attention_threshold,onTrackThreshold:row.on_track_threshold,ownerUserId:row.owner_user_id??'',governanceOwnerUserId:row.governance_owner_user_id??''}))
    }
  },[formulationId,organizationId])
  useEffect(()=>{void load()},[load])

  const save=async()=>{
    if(!formulationId)return
    if(!monitoringPackageDraftIsMaterializable(draft)){setSaveMessage('Defina os dois responsáveis, revise os limites e informe uma justificativa com pelo menos 10 caracteres.');return}
    setSaving(true);setSaveMessage('')
    const {error}=await supabase.rpc('configure_skpe_monitoring_package',{p_formulation_id:formulationId,p_payload:{
      cycleFrequency:draft.cycleFrequency,reviewFrequency:draft.reviewFrequency,cycleOverlapPolicy:draft.cycleOverlapPolicy,
      evidenceRequired:draft.evidenceRequired,dataQualityRequired:draft.dataQualityRequired,confidenceRequiredForKeyResults:draft.confidenceRequiredForKeyResults,
      allowManualProgressOverride:draft.allowManualProgressOverride,dataFreshnessDays:draft.dataFreshnessDays,lateToleranceDays:draft.lateToleranceDays,
      aggregationPolicy:draft.aggregationPolicy,criticalThreshold:draft.criticalThreshold,attentionThreshold:draft.attentionThreshold,onTrackThreshold:draft.onTrackThreshold,
      ownerUserId:draft.ownerUserId,governanceOwnerUserId:draft.governanceOwnerUserId
    },p_change_reason:draft.changeReason.trim()})
    setSaving(false);if(error){setSaveMessage(error.message);return}
    setSaveMessage('Governança da execução salva em elaboração. Nenhuma validação ocorreu automaticamente.');setDraft((current)=>({...current,changeReason:''}));await load();onChanged?.()
  }

  const transition=async(action:'submit'|'validate'|'return',reason:string,notes:string)=>{
    if(!formulationId)return
    setTransitioning(true);setWorkflowMessage('')
    const {error}=await supabase.rpc('transition_skpe_monitoring_package',{p_formulation_id:formulationId,p_action:action,p_validation_notes:notes.trim()||null,p_change_reason:reason.trim()})
    setTransitioning(false);if(error){setWorkflowMessage(error.message);return}
    setWorkflowMessage(action==='submit'?'Governança submetida à validação humana.':action==='validate'?'Governança da execução validada humanamente.':'Governança devolvida para ajustes.');await load();onChanged?.()
  }

  if(!formulationId)return null
  return <section>
    <header className="skpe-strategic-readiness-header"><div><p className="skpe-eyebrow">Área de trabalho</p><h3>Governança da Execução</h3><p>Defina cadência, critérios, responsáveis e regras do monitoramento antes de iniciar a operação da estratégia.</p></div></header>
    {canManage?<MonitoringPackageConfigurationPanel draft={draft} owners={owners} saving={saving} message={saveMessage} onChange={(patch)=>setDraft((current)=>({...current,...patch}))} onSave={()=>void save()}/>:<p>Você pode consultar a governança, mas não alterá-la.</p>}
    <MonitoringPackageWorkflowPanel status={readiness?.packageStatus??null} readyForValidation={Boolean(readiness?.readyForValidation)} canSubmit={canManage} canValidate={canValidate} transitioning={transitioning} message={workflowMessage} onTransition={(action,reason,notes)=>void transition(action,reason,notes)}/>
  </section>
}
