# Guia de Execução Controlada — FE-08 no Supabase Web

## 1. Objetivo

Executar e validar a FE-08 no projeto:

```text
skpe-saas-dev
South America — São Paulo
```

Sem utilizar Supabase local ou Docker.

---

## 2. Arquivos

### Migration

```text
supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql
```

### Verificador

```text
supabase/verification/verificar_fe08_monitoramento_governanca_aprendizado.sql
```

---

## 3. Pré-condições

Antes de executar:

1. confirme o projeto `skpe-saas-dev` no Supabase;
2. confirme que as migrations FE-00 a FE-07 foram executadas;
3. confirme que o verificador FE-07 retornou todos os controles como `OK`;
4. não execute em produção;
5. não fragmente a migration;
6. não altere o conteúdo no SQL Editor;
7. não abra interface React nesta etapa;
8. não realize merge.

---

## 4. Execução da migration

1. Acesse o Supabase Web.
2. Selecione `skpe-saas-dev`.
3. Abra **SQL Editor**.
4. Crie uma nova query.
5. Abra localmente o arquivo da migration.
6. Copie todo o conteúdo, da primeira à última linha.
7. Cole no SQL Editor.
8. Confirme que o script inicia com `begin;` e termina com `commit;`.
9. Clique em **Run** uma única vez.
10. Aguarde a conclusão.

### Resultado esperado

```text
Success. No rows returned
```

A mensagem pode variar, mas não deve existir erro SQL.

### Em caso de erro

1. não execute partes isoladas;
2. copie a mensagem completa;
3. registre linha, função e código do erro;
4. não edite a migration diretamente no Supabase;
5. interrompa a preparação do commit;
6. retorne para correção controlada do arquivo-fonte.

A transação protege contra aplicação parcial quando o erro ocorrer antes do `commit`.

---

## 5. Execução do verificador

Após sucesso da migration:

1. crie outra query no SQL Editor;
2. copie todo o verificador;
3. execute;
4. analise o grid retornado.

### Resultado obrigatório

Todos os registros devem apresentar:

```text
status = OK
```

O verificador avalia, entre outros:

- 11 tabelas;
- 4 permissões;
- RLS;
- políticas SELECT;
- ausência de política `ALL`;
- ausência de DML direto para usuários comuns;
- DML do `service_role`;
- 23 RPCs públicas;
- funções internas protegidas;
- bloqueio das RPCs legadas;
- `SECURITY DEFINER`;
- `search_path`;
- gatilhos;
- imutabilidade dos snapshots;
- índices de unicidade submetido/validado.

### Se houver `NOK`

Não avance para commit.

Copie:

- `control_code`;
- `control_name`;
- `details`;
- eventual erro do Supabase.

---

## 6. Testes autenticados mínimos

O verificador de catálogo não substitui testes funcionais.

Realize com usuários de teste autorizados.

### 6.1 Permissão de consulta

Confirme que um perfil com `strategic_monitoring.view` consegue consultar e não consegue gravar diretamente nas tabelas.

### 6.2 Pacote FE-08

1. Configure o pacote em uma Formulação editável.
2. Submeta.
3. Valide com usuário autorizado.
4. Confirme auditoria.

### 6.3 Bloqueio da Formulação

Tente avançar uma Formulação sem pacote validado. O avanço deve ser bloqueado.

### 6.4 Abertura de ciclo

Com Formulação aprovada:

1. abra ciclo válido;
2. tente abrir ciclo sobreposto com política `block`;
3. confirme o bloqueio.

### 6.5 Medição de KPI

1. registre medição;
2. confirme situação `submitted`;
3. confirme que a projeção oficial não foi indevidamente alterada;
4. valide;
5. confirme situação `validated`;
6. registre correção;
7. rejeite a correção;
8. confirme que o validado anterior foi preservado;
9. valide nova correção;
10. confirme supersessão.

### 6.6 Check-in de KR

1. registre check-in;
2. valide;
3. confirme atualização do KR;
4. confirme recálculo do OKR;
5. confirme auditoria.

### 6.7 Check-in de Iniciativa

1. registre check-in de Iniciativa selecionada;
2. tente registrar para Iniciativa não selecionada;
3. confirme bloqueio;
4. valide o registro;
5. confirme projeção de progresso, custo, benefício, risco e saúde.

### 6.8 RAE

1. crie RAE;
2. adicione item tipado;
3. registre decisão;
4. informe data, síntese e conclusões;
5. ratifique;
6. tente reeditar a RAE;
7. confirme imutabilidade.

### 6.9 Fechamento

1. transicione o ciclo até `pending_ratification`;
2. execute a prontidão;
3. resolva bloqueios;
4. feche o ciclo;
5. confirme snapshot ratificado;
6. confirme SHA-256;
7. tente alterar ou excluir o snapshot;
8. confirme bloqueio;
9. reabra o ciclo;
10. confirme snapshot anterior como `superseded`.

---

## 7. Consultas de apoio

### Situação do pacote

```sql
select
  formulation_id,
  status,
  cycle_frequency,
  review_frequency,
  aggregation_policy,
  validated_at
from public.skpe_monitoring_packages
order by created_at desc;
```

### Ciclos

```sql
select
  id,
  code,
  name,
  period_start,
  period_end,
  status,
  opened_at,
  closed_at
from public.skpe_monitoring_cycles
order by period_start desc;
```

### Snapshots

```sql
select
  monitoring_cycle_id,
  snapshot_version,
  status,
  checksum_sha256,
  generated_at,
  ratified_at
from public.skpe_performance_snapshots
order by generated_at desc;
```

### Auditoria FE-08

```sql
select
  action_code,
  entity_type,
  entity_id,
  reason,
  actor_user_id,
  occurred_at
from public.skpe_operational_audit
where action_code like 'fe08.%'
order by occurred_at desc;
```

---

## 8. Registro da evidência

Guarde:

- captura do sucesso da migration;
- grid completo do verificador;
- evidências dos testes autenticados;
- data e usuário executor;
- eventuais observações;
- SHA-256 do pacote.

---

## 9. Autorização para Git

Somente após:

```text
migration = sucesso
verificador = todos OK
testes autenticados = aprovados
```

execute o script de preparação do commit.

Não realize merge em `develop` ou `main`.
