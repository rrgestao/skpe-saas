alter table public.skpe_evidence_checklists
  add column if not exists checklist_kind text not null default 'evidence_collection',
  add column if not exists target_journey_item_id uuid null,
  add column if not exists target_artifact_id uuid null,
  add column if not exists requirement_mode text not null default 'optional';

alter table public.skpe_evidence_checklists
  drop constraint if exists skpe_evidence_checklists_checklist_kind_check,
  add constraint skpe_evidence_checklists_checklist_kind_check
    check (checklist_kind in ('evidence_collection','delivery_readiness'));

alter table public.skpe_evidence_checklists
  drop constraint if exists skpe_evidence_checklists_requirement_mode_check,
  add constraint skpe_evidence_checklists_requirement_mode_check
    check (requirement_mode in ('optional','methodology_required','client_required'));

alter table public.skpe_evidence_checklists
  drop constraint if exists skpe_evidence_checklists_target_journey_item_id_fkey,
  add constraint skpe_evidence_checklists_target_journey_item_id_fkey
    foreign key (target_journey_item_id)
    references public.skpe_journey_items(id)
    on delete set null;

alter table public.skpe_evidence_checklists
  drop constraint if exists skpe_evidence_checklists_target_artifact_id_fkey,
  add constraint skpe_evidence_checklists_target_artifact_id_fkey
    foreign key (target_artifact_id)
    references public.sparks_methodology_artifacts(id)
    on delete set null;

alter table public.skpe_evidence_checklists
  drop constraint if exists skpe_evidence_checklists_delivery_readiness_target_check,
  add constraint skpe_evidence_checklists_delivery_readiness_target_check
    check (
      checklist_kind <> 'delivery_readiness'
      or target_journey_item_id is not null
      or target_artifact_id is not null
    );

create index if not exists idx_skpe_evidence_checklists_target_journey_item
  on public.skpe_evidence_checklists(target_journey_item_id)
  where target_journey_item_id is not null;

create index if not exists idx_skpe_evidence_checklists_target_artifact
  on public.skpe_evidence_checklists(target_artifact_id)
  where target_artifact_id is not null;

create index if not exists idx_skpe_evidence_checklists_kind_requirement
  on public.skpe_evidence_checklists(project_id, checklist_kind, requirement_mode);

comment on column public.skpe_evidence_checklists.checklist_kind is
  'Semantic purpose of the checklist instance: evidence collection or delivery readiness verification.';
comment on column public.skpe_evidence_checklists.target_journey_item_id is
  'Optional journey deliverable or other journey item whose readiness is verified by this checklist.';
comment on column public.skpe_evidence_checklists.target_artifact_id is
  'Optional methodology artifact whose readiness is verified by this checklist.';
comment on column public.skpe_evidence_checklists.requirement_mode is
  'Whether the checklist is optional, required by methodology, or required by the client/organization.';
