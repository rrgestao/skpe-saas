# Contrato de Onboarding e Carga Assistida de Cadastros Primários

## 1. Finalidade

Padronizar a implantação inicial de organizações na Plataforma SPARKs sem criar cargas diretas, opacas ou irreversíveis no banco.

## 2. Estrutura mínima do template

1. `00_INSTRUCOES`
2. `01_ORGANIZACOES`
3. `02_USUARIOS`
4. `03_VINCULOS`
5. `04_MODULOS_DA_ORGANIZACAO`
6. `05_PERFIS_POR_MODULO`
7. `06_CONTATOS_INSTITUCIONAIS`
8. `07_CNAES`
9. `08_AREAS_E_UNIDADES`
10. `09_PAPEIS_DE_GOVERNANCA`

## 3. Chaves funcionais

O arquivo utiliza chaves legíveis e estáveis:

- `organization_code`;
- `login_email`;
- `module_code`;
- `role_code`;
- `area_code`;
- `governance_role_code`.

UUIDs internos não são exigidos do usuário da implantação.

## 4. Pipeline obrigatório

1. upload e hash SHA-256;
2. validação estrutural;
3. normalização sem persistência;
4. conciliação com dados existentes;
5. simulação de criação, atualização, manutenção e rejeição;
6. revisão humana;
7. aprovação com justificativa;
8. gravação por RPC auditada;
9. relatório por linha;
10. capacidade de reversão por lote.

## 5. Identidade e e-mail

- `login_email` é individual e exclusivo por pessoa;
- `institutional_email` pode representar uma caixa compartilhada;
- pessoas diferentes não compartilham uma credencial;
- uma pessoa pode ter vários vínculos em `03_VINCULOS`.

## 6. Telefone

Valores aceitos:

- 10 dígitos para telefone fixo;
- 11 dígitos para celular, com nono dígito;
- apresentação formatada em padrão brasileiro;
- armazenamento canônico somente com dígitos.

## 7. Integrações futuras

O mesmo contrato semântico será reutilizado por CSV, ERP, legado, API, ETL e sincronizações programadas. O canal muda; as regras de validação, autoria, auditoria e conciliação permanecem.
