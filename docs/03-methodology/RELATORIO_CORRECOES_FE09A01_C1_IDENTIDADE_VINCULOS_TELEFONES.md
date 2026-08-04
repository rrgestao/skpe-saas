# Relatório de Correções — FE-09.A.01-C1

## 1. Escopo

Correções identificadas durante a carga controlada de usuários reais da COOTAQUARA:

- remoção do alerta indevido de falta de perfil no fluxo normal;
- descarte silencioso de rota administrativa antiga para usuário sem permissão;
- substituição de glifos de visualização por SVG;
- explicitação da manutenção de cargo/função no vínculo organizacional;
- reforço de que um usuário pode possuir vários vínculos organizacionais;
- distinção entre e-mail de acesso individual e e-mail institucional compartilhado;
- máscara, validação e normalização de telefone brasileiro;
- preparação do contrato de onboarding e carga assistida.

## 2. Decisões funcionais

### Identidade

Cada pessoa possui uma única identidade autenticável e um e-mail de acesso individual. Caixas compartilhadas são contatos institucionais, não credenciais de pessoas.

### Vínculo

O cargo/função pertence ao vínculo `usuário × organização`. A mesma pessoa pode exercer funções diferentes em organizações distintas.

### Telefone

A interface aceita:

- fixo: `(99) 9999-9999`;
- celular: `(99) 9 9999-9999`.

A persistência envia apenas os dígitos. A apresentação reaplica a máscara.

## 3. Delimitação técnica

Esta correção reutiliza a RPC auditada `upsert_platform_admin_membership` já existente para manutenção do vínculo pela Administração da Plataforma.

A habilitação equivalente dentro da Administração da Organização depende da inspeção objetiva dos contratos, gatilhos e trilhas de auditoria existentes. O script SQL incluído é somente leitura e deve ser executado antes de qualquer nova migration.

## 4. Segurança

- nenhum usuário existente é apagado;
- nenhum vínculo é recriado;
- nenhuma senha é alterada;
- nenhuma migration é aplicada automaticamente;
- nenhuma escrita é realizada no Supabase pelo instalador;
- nenhum staging, commit, push ou merge é executado.
