# 📘 Manual do Usuário — Sistema PCA ITPS
## Plano de Contratações Anual — Instituto Tecnológico e de Pesquisas do Estado de Sergipe

---

## 🔑 1. Acesso ao Sistema

### 1.1 Tela de Login
Ao abrir o aplicativo, a primeira tela exibida é a de **Login**. Digite seu usuário e senha fornecidos pelo administrador.

### 1.2 Perfis de Acesso

| Perfil | Usuário Exemplo | Permissões |
|---|---|---|
| **Administrador** | `admin` | Acesso total: visualiza todos os setores, controla prazos, gerencia contas, acessa Dashboard BI, copia dados entre anos |
| **Editor (Setor)** | `solos`, `quimica_aguas`, `microbiologia`, etc. | Visualiza e edita **apenas** os itens do seu setor. Pode finalizar planejamento |
| **Visualizador** | Contas configuradas como viewer | Apenas leitura. Não pode criar, editar ou excluir itens |

### 1.3 Senha Padrão
A senha padrão para todos os setores é `itps123`. O administrador pode alterá-la a qualquer momento pela tela de Contas de Acesso.

---

## 🧑‍💻 2. Guia do Operador (Setores / Laboratórios)

Os operadores dos setores (Solos, Química de Águas, Microbiologia, Inorgânica, Bromatologia, Orgânica, Qualidade, Geconf, GEAAD) possuem foco exclusivo no preenchimento das suas necessidades de contratação.

### 2.1 Tela Inicial — Listagem de Itens

Ao fazer login, o operador é direcionado à tela **"Itens do PCA"** contendo:

- **Cards de Métricas no Topo:**
  - **Valor Total Planejado:** Soma financeira de todos os itens cadastrados **apenas do seu setor**.
  - **Quantidade de Itens:** Total de itens cadastrados **apenas do seu setor**.

- **Barra de Busca:** Campo de pesquisa rápida por descrição, código ou subgrupo.

- **Filtro de Categoria:** Dropdown para filtrar por tipo de recurso (*Material de Consumo*, *Equipamento* ou *Serviço*).

- **Tabela de Itens:** Lista todos os itens cadastrados pelo setor com as colunas:
  - Origem / Recurso
  - Área / Subgrupo
  - Item / Código
  - Qtd / Unid
  - Valor Estimado
  - Ações (Editar / Excluir)

### 2.2 Cadastrar Novo Item

1. Clique no botão azul **"+ Novo Item PCA"** no canto superior direito.
2. Preencha o formulário:
   - **Item (Descrição):** Nome completo e detalhado do recurso *(obrigatório)*.
   - **Quantidade:** Quantidade necessária *(obrigatório)*.
   - **Valor Unitário:** Valor estimado por unidade em Reais *(obrigatório)*.
   - **Tipo:** Classificação livre (ex: Reagente, Padrão, Equipamento).
   - **Código:** Código de referência do produto, se houver.
   - **Unidade:** Unidade de medida (ex: Frasco, Litro, Unidade).
   - **Categoria:** Material de Consumo, Equipamento ou Serviço.
   - **Ano:** Ano do PCA (padrão: 2027).
3. O **Valor Total** é calculado automaticamente (Quantidade × Valor Unitário).
4. Clique em **"Salvar"** para registrar o item no banco de dados central.

### 2.3 Editar um Item Existente

1. Na tabela de itens, localize o item desejado.
2. Clique no ícone de **lápis azul** (✏️) na coluna "Ações".
3. O formulário será preenchido com os dados atuais. Modifique o que for necessário.
4. Clique em **"Salvar"** para confirmar as alterações.

### 2.4 Excluir um Item

1. Clique no ícone de **lixeira vermelha** (🗑️) na coluna "Ações".
2. Confirme a exclusão no diálogo de segurança.
3. O item será removido permanentemente do banco de dados.

### 2.5 Cronômetro Regressivo de Prazo

- Quando o administrador define um prazo limite, um **banner azul** aparece no topo da tela do operador informando:
  > "Período de Edição Liberado Temporariamente"
  > "Tempo restante para alterações: **falta X dias e Y horas e Z minutos e W segundos**"

- O cronômetro **decrementa em tempo real** (segundo a segundo).
- Quando o prazo expira, o banner muda automaticamente para **vermelho**:
  > "Período de Edição do PCA Bloqueado"

- Neste momento, todos os botões de criação, edição e exclusão são **ocultados da interface** e o backend passa a rejeitar qualquer tentativa de escrita.

### 2.6 Finalizar Planejamento

Quando o setor concluir todas as inserções e revisões:

1. Clique no botão verde **"✅ Finalizar Planejamento"** no cabeçalho superior direito.
2. Leia atentamente o aviso de confirmação:
   > *"Ao finalizar, todas as suas alterações serão salvas e o seu acesso de edição será bloqueado. Você não poderá criar, alterar ou excluir mais nenhum item, a menos que solicite a reabertura ao Administrador."*
3. Clique em **"Sim, Finalizar"** para confirmar.
4. Você será deslogado automaticamente e sua conta será marcada como **Bloqueada (Setor)**.

> ⚠️ **Atenção:** Esta ação é definitiva até que o administrador libere manualmente o acesso novamente.

### 2.7 Exportar Dados

Na barra de ações (ao lado da busca), existem dois botões de exportação:

| Ícone | Formato | Descrição |
|---|---|---|
| 📊 Verde | **CSV (Excel)** | Exporta planilha formatada para `C:\Users\gnsilva\Downloads\pca_export_ANO.csv` |
| 📄 Vermelho | **TXT (Relatório)** | Exporta relatório texto estruturado com cabeçalho ITPS para `C:\Users\gnsilva\Downloads\relatorio_pca_ANO.txt` |

---

## 👑 3. Guia do Administrador

O Administrador possui acesso completo e irrestrito a todas as funcionalidades do sistema.

### 3.1 Menu Lateral (Sidebar)

O menu lateral do administrador exibe as seguintes opções:

| Item do Menu | Descrição |
|---|---|
| **Dashboard BI** | Painel analítico com gráficos e métricas consolidadas |
| **Itens do PCA** | Listagem geral de todos os itens de todos os setores |
| **Contas de Acesso** | Gerenciamento de usuários, senhas e permissões |
| **Parâmetros** | Configuração de laboratórios, categorias, tipos de recurso e prazo limite |

Adicionalmente, o admin possui:
- **Seletor de Ano:** Dropdown para alternar entre os anos do PCA (2026–2030).
- **Botão de Cópia:** Ícone ao lado do seletor de ano para duplicar dados de um ano para o próximo.
- **Filtros de Planilha:** Filtro lateral por pasta (Todos os Itens / Laboratórios / GEAAD).

### 3.2 Dashboard BI (Analítico)

Acesso exclusivo do Administrador. Apresenta:

1. **Cards de KPI (Indicadores no Topo):**
   - **Valor Total Planejado:** Soma geral de todos os setores.
   - **Quantidade de Itens:** Total geral de itens cadastrados.
   - **Média por Item:** Custo médio calculado automaticamente.

2. **Custo por Categoria de Recurso:**
   - Gráfico de barras horizontais mostrando a distribuição entre Material de Consumo, Equipamento e Serviço, com valor absoluto e percentual.

3. **Distribuição por Pasta:**
   - Separação visual entre "Laboratórios" e "GEAAD" com valor e percentual.

4. **Soma por Setor / Laboratório:**
   - Listagem detalhada e individual de **cada setor**, ordenada do maior para o menor custo planejado.
   - Exibe: nome do setor, quantidade de itens, valor total em R$ e percentual do orçamento geral.

### 3.3 Contas de Acesso (Gerenciamento de Usuários)

#### Criar Novo Usuário
1. No formulário à esquerda, preencha:
   - **Nome Completo:** Nome do setor ou pessoa.
   - **Usuário (login):** Username para autenticação.
   - **Senha:** Senha de acesso.
   - **Perfil:** Visualizador, Editor ou Administrador.
2. Clique em **"Salvar Usuário"**.
3. Ao criar um usuário com perfil Editor, o sistema **cria automaticamente** o laboratório/categoria correspondente no banco de dados.

#### Editar Conta Existente
1. Na lista de contas ativas à direita, clique no ícone de **lápis** (✏️).
2. Altere os campos desejados:
   - Nome, Username, Senha, Perfil de Acesso.
   - **Switch "Bloquear Edição":** Quando ativado, impede o setor de fazer qualquer alteração.
3. Clique em **"Salvar Alterações"**.

#### Badges de Status das Contas
Cada conta exibe um badge visual indicando seu estado atual:

| Badge | Cor | Significado |
|---|---|---|
| `Liberado` | 🟢 Verde | Conta ativa e autorizada a editar |
| `Bloqueado (Setor)` | 🔴 Vermelho | Conta travada manualmente ou após finalização do planejamento |
| `Bloqueado (Geral)` | 🔴 Vermelho | Prazo global de edição expirou ou está inativo |

#### Excluir Conta
1. Clique no ícone de **lixeira** (🗑️) ao lado da conta.
2. Confirme a exclusão no diálogo de segurança.

### 3.4 Parâmetros do Sistema

A tela de Parâmetros é dividida em abas:

#### Aba 1 — Laboratórios
- Adicionar ou remover laboratórios/setores disponíveis nos formulários de cadastro.

#### Aba 2 — Categorias
- Gerenciar as categorias de agrupamento dos itens (ex: Laboratórios, PCA, GEAAD).

#### Aba 3 — Tipos de Recurso
- Gerenciar os tipos de recurso disponíveis (Material de Consumo, Equipamento, Serviço).

#### Aba 4 — Prazo Limite PCA ⏰
Esta é a aba mais estratégica do sistema:

1. **Selecionar Data Limite:**
   - Clique no campo de data para abrir o seletor visual de calendário.
   - Escolha o dia exato de encerramento.

2. **Selecionar Hora Limite:**
   - Clique no campo de hora para abrir o seletor visual de relógio.
   - Escolha a hora exata (ex: 18:00).

3. **Salvar Prazo:**
   - Clique no botão **"Salvar Prazo"**.
   - O sistema ativa imediatamente o cronômetro regressivo para todos os setores.

4. **Bloquear Já:**
   - Em caso de emergência, clique no botão vermelho **"Bloquear Já"**.
   - Isso encerra instantaneamente o período de edição para todos os setores, sem esperar a data configurada.

### 3.5 Cópia de Dados entre Anos

1. No seletor de ano do menu lateral, escolha o ano de origem (ex: 2026).
2. Clique no ícone de **cópia** (📋) ao lado do seletor.
3. O sistema perguntará se deseja copiar os dados de 2026 para 2027.
4. **Segurança:** É necessário digitar a palavra **COPIAR** no campo de confirmação.
5. Clique em **"Confirmar Cópia"**.

> ⚠️ **Atenção:** Se já existirem itens no ano de destino, eles serão **substituídos** pela cópia.

---

## 🛡️ 4. Regras de Segurança

| Regra | Descrição |
|---|---|
| **Default Bloqueado** | Se nenhum prazo for definido, o sistema considera a edição bloqueada para todos os setores |
| **Validação no Servidor** | Mesmo que alguém tente burlar a interface, o backend rejeita operações de escrita se o prazo expirou ou a conta está travada |
| **Isolamento de Dados** | Cada setor só visualiza e manipula seus próprios itens. O admin é o único que enxerga tudo |
| **Pergunta de Segurança** | Operações críticas (cópia de ano, exclusão) exigem confirmação explícita |

---

## 🖥️ 5. Requisitos Técnicos

| Componente | Tecnologia |
|---|---|
| Frontend | Flutter (Windows Desktop) |
| Backend | Python + FastAPI |
| Banco de Dados | PostgreSQL (IP: 172.23.6.109) |
| Porta do Servidor | 8000 |

### Como Iniciar o Sistema
1. O aplicativo inicia o backend automaticamente ao ser aberto (se não estiver rodando).
2. Basta abrir o executável `app.exe` e fazer login.

---

## 📞 6. Suporte

Em caso de dúvidas ou problemas técnicos, entre em contato com o setor de Tecnologia da Informação do ITPS.
