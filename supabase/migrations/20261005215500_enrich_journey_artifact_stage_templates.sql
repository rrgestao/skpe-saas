-- Enriches future Journey artifact proposals with stage-specific working and validation structures.
-- Does not create evidence, approval, validation or Journey promotion.

create or replace function public.skpe_build_journey_artifact_markdown(
  target_item_id uuid,
  target_artifact_role text
)
returns text
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  v_item public.skpe_journey_items%rowtype;
  v_project public.skpe_projects%rowtype;
  v_suggestions text;
  v_title text;
  v_stage_body text;
  v_role_body text;
begin
  select * into v_item
  from public.skpe_journey_items
  where id=target_item_id
    and archived_at is null;

  if v_item.id is null then
    raise exception using errcode='22023',message='Item da Jornada não encontrado.';
  end if;

  select * into v_project
  from public.skpe_projects
  where id=v_item.project_id
    and archived_at is null;

  if v_project.id is null then
    raise exception using errcode='22023',message='Projeto SK-PE ativo não encontrado.';
  end if;

  v_suggestions:=public.skpe_journey_item_suggestion_text(
    v_item.code,v_item.name,v_item.description,v_item.item_type
  );

  v_title:=case target_artifact_role
    when 'validation' then 'Pacote para Validação'
    when 'followup' then 'Registro de Acompanhamento'
    when 'activity_plan' then 'Plano de Trabalho'
    else 'Caderno de Trabalho e Recomendações'
  end;

  v_stage_body:=case v_item.code
    when 'PEM-03.01' then
      E'## Estrutura de trabalho sugerida\n\n'
      ||E'| OE relacionado | Objetivo do OKR | Resultado-Chave | Indicador/unidade | Linha de base | Fonte | Meta anual | Ciclo relacionado | Situação |\n'
      ||E'|---|---|---|---|---|---|---|---|---|\n'
      ||E'| A confirmar | Proposta SPARKs | Proposta mensurável | A definir | A confirmar | A confirmar | 2026–2030 | A relacionar | Proposta |\n\n'
      ||E'### Critérios mínimos\n\n'
      ||E'- O Objetivo do OKR deve ser qualitativo, mobilizador e não mera cópia do Objetivo Estratégico.\n'
      ||E'- Cada KR deve medir resultado ou mudança observável; atividades pertencem às iniciativas.\n'
      ||E'- Linha de base, fonte, unidade, polaridade, prazo e trajetória anual devem estar explícitos antes da validação.\n'
      ||E'- 2026 pode ser tratado como transição/confirmação de baseline quando a implantação ocorrer com o exercício em andamento.\n'
    when 'PEM-03.02' then
      E'## Matriz sugerida de indicadores e metas\n\n'
      ||E'| Resultado/Objetivo | Indicador | Fórmula | Unidade | Polaridade | Fonte | Periodicidade | Responsável pela apuração | Linha de base | 2026 | 2027 | 2028 | 2029 | 2030 |\n'
      ||E'|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n'
      ||E'| A relacionar | Proposta SPARKs | A definir | A definir | A definir | Evidência própria/benchmark identificado | A definir | A validar | A confirmar | Transição/baseline quando aplicável | Proposta | Proposta | Proposta | Proposta |\n\n'
      ||E'### Regra de qualidade\n\n'
      ||E'- Benchmark é referência comparativa, não evidência própria da Organização.\n'
      ||E'- Sem linha de base ou fonte confiável, a meta deve permanecer provisória ou ser substituída por ação de instrumentação.\n'
    when 'PEM-03.03' then
      E'## Portfólio sugerido de iniciativas e projetos\n\n'
      ||E'| KR/OE | Iniciativa | Contribuição esperada | Ciclo de Evolução | Prioridade | Esforço/custo | Dependências | Riscos | Responsável | Prazo |\n'
      ||E'|---|---|---|---|---|---|---|---|---|---|\n'
      ||E'| A relacionar | Proposta SPARKs | A justificar | A alocar | A priorizar | A estimar | A mapear | A mapear | A validar | Dentro do Ciclo aplicável |\n\n'
      ||E'### Critérios de priorização\n\n'
      ||E'- Contribuição direta para KRs e OEs.\n'
      ||E'- Compatibilidade com maturidade, capacidade, recursos e dependências.\n'
      ||E'- Relação esforço x impacto e risco de execução.\n'
      ||E'- Iniciativas podem ser substituídas quando alternativa melhor surgir antes da validação institucional.\n'
    when 'PEM-03.04' then
      E'## Matriz sugerida de governança da execução\n\n'
      ||E'| Decisão/rito | Finalidade | Patrocinador | Responsável | Participantes | Cadência | Alçada | Evidência/registro | Escalonamento |\n'
      ||E'|---|---|---|---|---|---|---|---|---|\n'
      ||E'| A definir | A definir | A validar | A validar | A validar | A propor | A propor | A definir | A definir |\n\n'
      ||E'### Pontos de decisão\n\n'
      ||E'- Quem decide, quem recomenda, quem executa e quem precisa ser informado.\n'
      ||E'- Qual desvio exige escalonamento e em quanto tempo.\n'
      ||E'- Como registrar replanejamentos sem apagar histórico.\n'
    when 'PEM-04.01' then
      E'## Plano sugerido de ativação\n\n'
      ||E'| Iniciativa aprovada | Onda/Ciclo | Marco | Dependência | Recurso/capacidade | Responsável | Data proposta | Condição de prontidão |\n'
      ||E'|---|---|---|---|---|---|---|---|\n'
      ||E'| A relacionar | A definir | A definir | A mapear | A confirmar | A validar | A propor | A definir |\n\n'
      ||E'Não iniciar ações automaticamente. A ativação depende de prontidão e validação das condições de execução.\n'
    when 'PEM-04.02' then
      E'## Plano sugerido de comunicação e mobilização\n\n'
      ||E'| Público | Objetivo | Mensagem-chave | Canal | Momento/cadência | Responsável | Evidência de alcance | Feedback esperado |\n'
      ||E'|---|---|---|---|---|---|---|---|\n'
      ||E'| Gestão/Conselhos/Equipe/Cooperados/Outros | A definir | Proposta SPARKs | A definir | A definir | A validar | A definir | A definir |\n\n'
      ||E'Nenhuma comunicação é disparada por este artefato. Ele apenas organiza a proposta para validação.\n'
    when 'PEM-04.03' then
      E'## Matriz sugerida de capacidades e mudança\n\n'
      ||E'| Capacidade necessária | Situação atual | Lacuna | Impacto na estratégia | Tratamento | Responsável | Prazo | Evidência de evolução |\n'
      ||E'|---|---|---|---|---|---|---|---|\n'
      ||E'| Pessoas/processos/tecnologia/gestão | A avaliar | A confirmar | A avaliar | Proposta SPARKs | A validar | A propor | A definir |\n\n'
      ||E'Quando não houver lacuna material, registrar explicitamente a não aplicabilidade em vez de criar ação artificial.\n'
    when 'PEM-04.04' then
      E'## Matriz sugerida de riscos da implementação\n\n'
      ||E'| Risco | Causa | Consequência | Probabilidade | Impacto | Controles atuais | Resposta | Responsável | Prazo | Indicador/evidência |\n'
      ||E'|---|---|---|---|---|---|---|---|---|---|\n'
      ||E'| A identificar | A confirmar | A confirmar | A avaliar | A avaliar | A levantar | A propor | A validar | A propor | A definir |\n\n'
      ||E'Risco alto ou crítico exige responsável, resposta, plano e prazo antes de validação. Aceitação exige justificativa explícita.\n'
    when 'PEM-05.01' then
      E'## Registro sugerido da rotina de monitoramento\n\n'
      ||E'| Elemento monitorado | Resultado atual | Meta | Desvio | Evidência/fonte | Confiança do dado | Responsável | Ação imediata |\n'
      ||E'|---|---|---|---|---|---|---|---|\n'
      ||E'| KPI/KR/Iniciativa/Risco | A apurar | A recuperar | A calcular | A vincular | A avaliar | A identificar | Se necessária |\n'
    when 'PEM-05.02' then
      E'## Roteiro sugerido de análise crítica\n\n'
      ||E'| Resultado | Meta | Desvio | Causa evidenciada | Risco/oportunidade | Decisão necessária | Responsável | Prazo |\n'
      ||E'|---|---|---|---|---|---|---|---|\n'
      ||E'| A analisar | A recuperar | A calcular | A demonstrar | A avaliar | A formular | A validar | A definir |\n\n'
      ||E'Diferenciar causa comprovada de hipótese. Hipóteses devem permanecer identificadas até contraprova.\n'
    when 'PEM-05.03' then
      E'## Registro sugerido de aprendizado e melhoria\n\n'
      ||E'| Aprendizado | Evidência | O que funcionou/não funcionou | Melhoria proposta | Prioridade | Responsável | Prazo | Como verificar |\n'
      ||E'|---|---|---|---|---|---|---|---|\n'
      ||E'| A registrar | A vincular | A analisar | Proposta SPARKs | A priorizar | A validar | A propor | A definir |\n'
    when 'PEM-05.04' then
      E'## Matriz sugerida de atualização estratégica\n\n'
      ||E'| Elemento vigente | Evidência que justifica revisão | Alteração proposta | Impactos | Decisão necessária | Vigência proposta | Histórico preservado |\n'
      ||E'|---|---|---|---|---|---|---|\n'
      ||E'| OE/KR/Meta/Iniciativa/Governança | A demonstrar | Proposta SPARKs | A avaliar | A submeter | A definir | Sim |\n\n'
      ||E'Atualização estratégica só deve ocorrer quando evidências justificarem a mudança e houver decisão governada.\n'
    else
      E'## Estrutura de trabalho sugerida\n\n'
      ||E'- Registrar fatos confirmados, hipóteses, recomendações e decisões pendentes separadamente.\n'
      ||E'- Vincular propostas às evidências e às decisões anteriores da Jornada.\n'
      ||E'- Identificar responsáveis e prazos somente como proposta até validação quando aplicável.\n'
  end;

  v_role_body:=case target_artifact_role
    when 'validation' then
      E'## Decisões para validação\n\n'
      ||E'Para cada item submetido, registrar uma das decisões: **aprovar**, **aprovar com ajustes** ou **devolver para revisão**.\n\n'
      ||E'| Item submetido | Recomendação SPARKs | Decisão | Ajustes/condições | Instância/papel decisor | Referência da reunião/ata |\n'
      ||E'|---|---|---|---|---|---|\n'
      ||E'| A preencher | A preencher | Pendente | — | A confirmar | A registrar |\n'
    when 'followup' then
      E'## Acompanhamento\n\n'
      ||E'| Data | Fato observado | Evidência | Desvio/risco | Decisão ou ação | Responsável | Prazo |\n'
      ||E'|---|---|---|---|---|---|---|\n'
      ||E'| A registrar | A registrar | A vincular | A avaliar | A registrar | A identificar | A definir |\n'
    when 'activity_plan' then
      E'## Plano de trabalho\n\n'
      ||E'| Ação | Entrega | Dependência | Responsável proposto | Prazo proposto | Evidência esperada | Situação |\n'
      ||E'|---|---|---|---|---|---|---|\n'
      ||E'| A definir | A definir | A mapear | A validar | A propor | A definir | Proposta |\n'
    else
      E'## Síntese da recomendação SPARKs\n\n'
      ||E'Revisar as propostas abaixo antes de apresentá-las à Organização. Nenhuma recomendação deve ser preservada apenas por ter aparecido em versão anterior; substituir ou aperfeiçoar quando houver alternativa tecnicamente melhor.\n'
  end;

  return
    '# '||v_title||' — '||v_item.name||E'\n\n'
    ||'**Situação:** Proposta SPARKs para trabalho e validação.  '||E'\n'
    ||'**Jornada:** '||v_item.code||' — '||v_item.name||'  '||E'\n'
    ||'**Projeto:** '||coalesce(v_project.name,'Planejamento Estratégico')||E'\n\n'
    ||'> Este artefato é disponibilizado automaticamente com a abertura da etapa. '
    ||'Seu conteúdo é uma sugestão metodológica e não representa decisão institucional, aprovação, evidência ou aceite da Organização.'
    ||E'\n\n## Por que esta etapa importa\n\n'
    ||coalesce(nullif(trim(v_item.description),''),'Esta etapa organiza uma parte necessária da evolução do Planejamento Estratégico e prepara decisões rastreáveis para as fases seguintes.')
    ||E'\n\n## Sugestões SPARKs\n\n'
    ||v_suggestions||E'\n\n'
    ||v_role_body||E'\n\n'
    ||v_stage_body
    ||E'\n\n## Evidências e dados necessários\n\n'
    ||E'- Usar fontes já reconhecidas na Jornada e contraprovas que sustentem linha de base, meta, risco ou decisão.\n'
    ||E'- Distinguir evidência confirmada, hipótese, benchmark, recomendação e decisão pendente.\n'
    ||E'- Registrar a interação humana que efetivamente ocorrer; não fabricar reunião, aceite, data ou responsável.\n'
    ||E'\n## Próximos passos\n\n'
    ||E'- Revisar tecnicamente a proposta.\n'
    ||E'- Submeter somente os pontos maduros à instância competente.\n'
    ||E'- Incorporar somente o que tiver sido efetivamente validado.\n'
    ||E'- Preservar propostas rejeitadas, substituídas ou ajustadas na trilha de auditoria.\n'
    ||E'- Atualizar os artefatos e a Jornada antes de abrir etapa dependente.';
end;
$function$;

revoke all on function public.skpe_build_journey_artifact_markdown(uuid,text) from public,anon;
grant execute on function public.skpe_build_journey_artifact_markdown(uuid,text) to authenticated,service_role;

comment on function public.skpe_build_journey_artifact_markdown(uuid,text) is
'Builds stage-specific SPARKs proposal artifacts for Journey work/validation. Read-only; does not create evidence, approval or Journey promotion.';
