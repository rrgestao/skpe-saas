# RELATÓRIO FORENSE — MIGRATIONS C9-C AUSENTES

## 1. Sumário executivo

- O que aconteceu: duas migrations identificadas na instância Supabase (versões `20260813220018` e `20260813220033`) não existem no repositório Git local (`supabase/migrations/`).
- SQLs originais recuperados: SIM (extratos registrados na tabela `supabase_migrations.schema_migrations`).
- Causa raiz: R3 — SQL foi executado diretamente no Supabase (registro indica `created_by = rr.gestao@gmail.com`).
- Possibilidade de restauração: Alta — statements originais foram extraídos da metadata e podem ser restaurados como arquivos de migration históricos com prova forte (ver seção 7).
- Situação do gate: C9-E permanece BLOQUEADO até reconciliação formal.


## 2. Identificação do repositório

- root: C:/DADOS/SPARKs/skpe-saas
- remote: https://github.com/rrgestao/skpe-saas.git
- branch: feature/formulacao-estrategica-operacional
- HEAD: 502608f578ae582ccf1514afd25d8d0ce458f0f2
- estado de working tree: limpo (nenhuma alteração commitada; relatório novo não commitado)

Comandos de preservação executados: `git rev-parse --show-toplevel`, `git branch --show-current`, `git rev-parse HEAD`, `git status --short --branch`, `git remote -v`, `git log -5 --oneline --decorate` (saídas registradas anteriormente).


## 3. Migrations investigadas

Tabela resumo:

Versão | Nome | Supabase | Git atual | Original recuperado | Evidência
---|---|---:|---|---:|---
20260813220018 | c9c_key_result_parent_handler | registrada (supabase_migrations) | ausente | SIM | `supabase_migrations.schema_migrations.statements` (conteúdo fornecido)
20260813220033 | c9c_register_key_result_parent_handler | registrada (supabase_migrations) | ausente | SIM | `supabase_migrations.schema_migrations.statements` (conteúdo fornecido)


## 4. Evidências locais e Git

- Pesquisa recursiva no workspace por nomes e padrões (`20260813220018`, `20260813220033`, `c9c_key_result_parent_handler`, etc.) → nenhum arquivo correspondente encontrado.
- `git ls-files supabase/migrations` → 94 migrations listadas; as versões `20260813220018` e `20260813220033` não estão presentes.
- `git log --all` / `git grep` / `git reflog` / busca em branches remotas → sem correspondência para os padrões procurados.
- Conclusão local/Git: não há histórico nem blobs no repositório que contenham as migrations procuradas.


## 5. Evidências obtidas do Supabase

Fonte: `supabase_migrations.schema_migrations` (consulta fornecida pelo usuário). Colunas relevantes detectadas:
- `version` (text)
- `statements` (ARRAY)
- `name` (text)
- `created_by` (text)
- `idempotency_key` (text)
- `rollback` (ARRAY)

Resultados para as versões investigadas (statements consolidados pelo usuário):

--- 20260813220018 — `c9c_key_result_parent_handler` (created_by: rr.gestao@gmail.com) ---

Conteúdo (STATEMENT único na array):

```sql
create or replace function public.skpe_execute_resolution_handler_key_result_parent_okr_candidate(p_source_value text,p_project_id uuid,p_config jsonb)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_kr_code text := nullif(btrim(p_source_value),'');
  v_formulation_id uuid;
  v_import_record_id uuid;
  v_parent_code text;
  v_parent_id uuid;
  v_parent_title text;
  v_parent_count integer;
  v_objective_id uuid;
  v_objective_code text;
  v_objective_name text;
  v_objective_count integer;
begin
  if p_config is null or jsonb_typeof(p_config) <> 'object' then
    raise exception using errcode='22023',message='Configuração do handler deve ser objeto JSON.';
  end if;
  if p_project_id is null or v_kr_code is null then
    return jsonb_build_object('resolution_status','blocked','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_kr_code,'warnings','[]'::jsonb,'blockers',jsonb_build_array(jsonb_build_object('code','KEY_RESULT_RESOLUTION_INPUT_MISSING')),'requires_human_review',true);
  end if;
  begin
    v_formulation_id := nullif(btrim(p_config->>'formulation_id'),'')::uuid;
    v_import_record_id := nullif(btrim(p_config->>'import_record_id'),'')::uuid;
  exception when others then
    raise exception using errcode='22023',message='formulation_id/import_record_id inválido no resolver_config.';
  end;
  select nullif(btrim(r.values_json->>'okr'),'') into v_parent_code
  from public.skpe_import_records r
  where r.id=v_import_record_id and r.project_id=p_project_id and r.entity_code='key_result';
  if v_parent_code is null then
    return jsonb_build_object('resolution_status','blocked','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_kr_code,'warnings','[]'::jsonb,'blockers',jsonb_build_array(jsonb_build_object('code','PARENT_OKR_CODE_MISSING')),'requires_human_review',true);
  end if;
  select count(*) into v_parent_count
  from public.skpe_okrs o
  where o.project_id=p_project_id and o.formulation_id=v_formulation_id and o.code=v_parent_code;
  if v_parent_count=0 then
    return jsonb_build_object('resolution_status','requires_review','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_parent_code||':'||v_kr_code,'target_reference',jsonb_build_object('entity_type','key_result','code',v_kr_code,'parent_okr_code',v_parent_code),'resolution_details',jsonb_build_object('parent_match_count',0,'match_strategy','exact_parent_okr_then_primary_objective','semantic_inference',false),'warnings',jsonb_build_array(jsonb_build_object('code','PARENT_OKR_NOT_MATERIALIZED','parent_okr_code',v_parent_code)),'blockers','[]'::jsonb,'requires_human_review',true);
  elsif v_parent_count>1 then
    return jsonb_build_object('resolution_status','blocked','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_parent_code||':'||v_kr_code,'warnings','[]'::jsonb,'blockers',jsonb_build_array(jsonb_build_object('code','PARENT_OKR_AMBIGUOUS','match_count',v_parent_count)),'requires_human_review',true);
  end if;
  select o.id,o.title into v_parent_id,v_parent_title
  from public.skpe_okrs o
  where o.project_id=p_project_id and o.formulation_id=v_formulation_id and o.code=v_parent_code;
  select count(*) into v_objective_count
  from public.skpe_okr_objectives oo
  join public.skpe_strategic_objectives so on so.id=oo.strategic_objective_id
  where oo.okr_id=v_parent_id and oo.is_primary=true and so.project_id=p_project_id and so.formulation_id=v_formulation_id;
  if v_objective_count=0 then
    return jsonb_build_object('resolution_status','requires_review','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_parent_code||':'||v_kr_code,'target_reference',jsonb_build_object('entity_type','key_result','code',v_kr_code,'parent_okr_id',v_parent_id,'parent_okr_code',v_parent_code),'warnings',jsonb_build_array(jsonb_build_object('code','PRIMARY_STRATEGIC_OBJECTIVE_NOT_FOUND')),'blockers','[]'::jsonb,'requires_human_review',true);
  elsif v_objective_count>1 then
    return jsonb_build_object('resolution_status','blocked','resolution_mode','unresolved','target_entity_id',null,'target_external_key',v_parent_code||':'||v_kr_code,'warnings','[]'::jsonb,'blockers',jsonb_build_array(jsonb_build_object('code','PRIMARY_STRATEGIC_OBJECTIVE_AMBIGUOUS','match_count',v_objective_count)),'requires_human_review',true);
  end if;
  select so.id,so.code,so.name into v_objective_id,v_objective_code,v_objective_name
  from public.skpe_okr_objectives oo join public.skpe_strategic_objectives so on so.id=oo.strategic_objective_id
  where oo.okr_id=v_parent_id and oo.is_primary=true and so.project_id=p_project_id and so.formulation_id=v_formulation_id;
  return jsonb_build_object('resolution_status','resolved','resolution_mode','create_new_entity','target_entity_id',null,'target_external_key',v_parent_code||':'||v_kr_code,'target_reference',jsonb_build_object('entity_type','key_result','code',v_kr_code,'parent_okr_id',v_parent_id,'parent_okr_code',v_parent_code,'parent_okr_title',v_parent_title,'strategic_objective_id',v_objective_id,'strategic_objective_code',v_objective_code,'strategic_objective_name',v_objective_name,'project_id',p_project_id,'formulation_id',v_formulation_id),'resolution_details',jsonb_build_object('parent_match_count',1,'primary_objective_match_count',1,'match_strategy','exact_parent_okr_then_primary_objective','semantic_inference',false),'warnings','[]'::jsonb,'blockers','[]'::jsonb,'requires_human_review',true);
end;
$function$;
```

--- 20260813220033 — `c9c_register_key_result_parent_handler` (created_by: rr.gestao@gmail.com) ---

Conteúdo (dois statements na array):

Statement 1:

```sql
insert into public.skpe_incorporation_resolution_handlers(
  handler_code,handler_name,description,handler_type,handler_version,status,
  input_contract,output_contract,configuration_contract,allows_semantic_inference,metadata
)
select
  'key_result_parent_okr_candidate',
  'Key Result por OKR pai canônico',
  'Resolve deterministicamente o candidato canônico de Key Result a partir do código do KR e do OKR pai informado na origem, exigindo OKR materializado e Objetivo Estratégico primário no mesmo projeto e formulação.',
  'custom',1,'active',
  '{"required":["source_value","project_id","formulation_id","import_record_id"]}'::jsonb,
  '{"fields":["target_entity_id","target_external_key","target_reference","resolution_status","resolution_mode","resolution_details","warnings","blockers","requires_human_review"]}'::jsonb,
  '{"required":["formulation_id","import_record_id"],"defaults":{"same_project":true,"same_formulation":true}}'::jsonb,
  false,
  '{"roadmap_step":"CO-IMPORT-04-C9-C","deterministic":true,"semantic_inference":false,"materializes_entity":false,"parent_relation":"okr","objective_relation":"primary_objective_of_parent_okr"}'::jsonb
where not exists (
  select 1 from public.skpe_incorporation_resolution_handlers where handler_code='key_result_parent_okr_candidate'
);
```

Statement 2:

```sql
create or replace function public.skpe_execute_incorporation_resolution_handler(p_handler_code text,p_source_value text,p_project_id uuid,p_config jsonb)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_handler public.skpe_incorporation_resolution_handlers%rowtype;
begin
  if nullif(btrim(p_handler_code),'') is null then
    raise exception using errcode='22023',message='resolver_handler_code é obrigatório.';
  end if;
  select * into v_handler from public.skpe_incorporation_resolution_handlers where handler_code=p_handler_code;
  if v_handler.id is null then
    raise exception using errcode='55000',message='Handler de resolução não cadastrado.';
  end if;
  if v_handler.status <> 'active' then
    raise exception using errcode='55000',message='Handler de resolução não está ativo.';
  end if;
  case p_handler_code
    when 'journey_item_by_numeric_token' then
      return public.skpe_execute_resolution_handler_journey_item_by_numeric_token(p_source_value,p_project_id,p_config);
    when 'create_new_entity_by_source_key' then
      return public.skpe_execute_resolution_handler_create_new_entity_by_source_key(p_source_value,p_project_id,p_config);
    when 'canonical_entity_by_code' then
      return public.skpe_execute_resolution_handler_canonical_entity_by_code(p_source_value,p_project_id,p_config);
    when 'cross_sheet_positional_create_new_candidate' then
      return public.skpe_execute_resolution_handler_cross_sheet_positional_create_new_candidate(p_source_value,p_project_id,p_config);
    when 'key_result_parent_okr_candidate' then
      return public.skpe_execute_resolution_handler_key_result_parent_okr_candidate(p_source_value,p_project_id,p_config);
    else
      raise exception using errcode='0A000',message='Handler cadastrado ainda não possui executor implementado.';
  end case;
end;
$function$;
```

Fonte: resultado da consulta em `supabase_migrations.schema_migrations` fornecida pelo usuário (conteúdo acima).


## 6. Nível de evidência por migration

- 20260813220018: NÍVEL A — SQL integral disponível em `supabase_migrations.schema_migrations.statements` (fonte: Supabase metadata); `created_by` identifica usuário executor.
- 20260813220033: NÍVEL A — statements integrais disponíveis (insert + create function); `created_by` identifica usuário executor.

Justificativa: a tabela `schema_migrations` no schema `supabase_migrations` contém os statements executados/registrados pela plataforma; isso corresponde exatamente ao requisito de prova forte (NÍVEL A) definido nas etapas forenses.


## 7. Linha do tempo forense (resumo)

Data/hora | Fonte | Evento | Evidência
---|---|---|---
2026-08-13 (preservação) | workspace local | Auditoria forense iniciada | `git` status, branch, HEAD, lista de migrations
(antes de 2026-08-13) | Supabase metadata | Entradas `20260813220018` e `20260813220033` registradas | `supabase_migrations.schema_migrations` (statements e created_by)
2026-08-13 | repositório local | buscas em Git e workspace | `git grep`, `git log --all`, `git ls-files` — sem correspondência

Observação: não foi possível obter timestamps exatos de execução a partir dos dados fornecidos; se desejar, peça para extrair a coluna `created_at`/`executed_at` da tabela `schema_migrations` para enriquecer a linha do tempo.


## 8. Causa raiz

Categoria: R3 — SQL foi executado diretamente no Supabase sem arquivo de migration persistido no repositório.

Nível de confiança: ALTO

Justificativa:
- statements integrais recuperados do schema `supabase_migrations.schema_migrations` (evidência NÍVEL A).
- `created_by` está preenchido com `rr.gestao@gmail.com`, indicando execução por usuário (provavelmente via Supabase SQL editor ou CLI) e não por commit versionado no Git.
- buscas em todo o repositório (commits, blobs, reflog, branches, stashes) não encontraram registros dos arquivos pesquisados.


## 9. Análise de segurança

- As duas migrations criam funções `SECURITY DEFINER` e inserem registro de handler; ambos são estruturas sensíveis.
- Recomenda-se revisar `search_path`, `owner` e permissões das functions recém-criadas no Supabase, especialmente `SECURITY DEFINER` e execuções por roles como `anon`/`authenticated`.
- Não foram feitas alterações no banco por este agente; apenas registro e export do SQL.


## 10. Alterações realizadas

Nenhuma alteração foi realizada no repositório ou no Supabase durante esta investigação.


## 11. Recomendações e ação mínima segura para restaurar rastreabilidade

1. Criar arquivos de migration com o conteúdo original recuperado a partir de `supabase_migrations.schema_migrations.statements` exatamente como registrados (sem alterar conteúdo). Gravar os arquivos em `supabase/migrations/` com os nomes originais: 
   - `20260813220018_c9c_key_result_parent_handler.sql`
   - `20260813220033_c9c_register_key_result_parent_handler.sql`

   Antes de escrever, registrar a fonte (consulta SQL na `schema_migrations`) e o hash do blob restaurado.

2. NÃO COMMITAR ou PUSH automático. Apresentar os arquivos restaurados para revisão humana (autor/owner) e obter autorização para commit. Documentar autor responsável (`created_by`) na mensagem de commit proposta.

3. Depois de aprovado, adicionar os arquivos ao Git e gerar um PR de reconciliação que explique que as migrations foram aplicadas diretamente no Supabase e são restauradas no repositório para manter rastreabilidade. Incluir referências ao relatório forense.

4. Revisar, em ambiente controlado, se aplicar forward-only corrections são necessárias (por exemplo, se o runtime difere do conteúdo recuperado). Se for o caso, proceder com migration forward-only documentada.


## 12. Divergências remanescentes

- Ausência de timestamps/executed_at na evidência fornecida. Recomenda-se extrair `executed_at`/`created_at` de `schema_migrations` para completar timeline.
- Verificar se outras migrations foram aplicadas diretamente e não versionadas.


## 13. Conclusão e próximo passo imediato

- RECUPERAÇÃO FORENSE CONCLUÍDA: SIM
- CAUSA RAIZ: R3
- CONFIANÇA: ALTO

20260813220018: ORIGINAL RECUPERADO (NÍVEL A — metadata Supabase)

20260813220033: ORIGINAL RECUPERADO (NÍVEL A — metadata Supabase)

ARQUIVOS RESTAURADOS: NENHUM (ainda não foi escrito no repositório; recomenda-se restaurar os arquivos como próximos passos seguindo a ação mínima segura descrita)

RECOMENDAÇÃO: B — Restaurar os arquivos originais no repositório e preparar PR de reconciliação após revisão humana.

GATE: C9-E permanece BLOQUEADO até nova reconciliação formal Supabase × GitHub.


---

(Guardarei este relatório em `docs/auditoria/` e calcularei hash/tamanho nos próximos passos.)
