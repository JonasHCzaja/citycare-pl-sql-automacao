# CityCare — Automação em PL/SQL
 
Camada de banco do CityCare: modelo relacional e automação de processos de gestão urbana com
procedures e triggers em Oracle.
 
## Sobre
 
O CityCare registra ocorrências urbanas, medições ambientais e serviços de limpeza, e avisa os
moradores afetados. Este repositório contém a parte que vive **dentro do banco**: o modelo de
dados, as procedures de entrada e os gatilhos que reagem a mudanças nas tabelas.
 
É um dos três repositórios do projeto:
 
| Parte | Repositório |
|---|---|
| Aplicação mobile | `[preencher]` |
| API backend | `[preencher]` |
| **Automação em PL/SQL** | este |
 
## Stack
 
- Oracle Database
- PL/SQL — procedures e triggers
- SQL Developer, ou outro cliente compatível com Oracle
## Como rodar
 
**Pré-requisito:** uma instância Oracle acessível e um cliente SQL.
 
```bash
git clone https://github.com/JonasHCzaja/citycare-pl-sql-automacao.git
cd citycare-pl-sql-automacao
```
 
Conecte ao banco e execute o script:
 
```sql
@citycare-automacao.sql
```
 
Confira o resultado — objeto com status diferente de `VALID` não compilou:
 
```sql
select object_name, object_type, status
from user_objects
where object_type in ('TABLE','TRIGGER','PROCEDURE','SEQUENCE')
order by object_type, object_name;
```
 
Detalhes dos erros de compilação ficam em `user_errors`.
 
## Modelo
 
Seis tabelas, todas ligadas a `tb_localizacao`:
 
| Tabela | Guarda |
|---|---|
| `tb_localizacao` | endereço — estado, cidade, bairro, logradouro, número |
| `tb_usuario` | morador ou administrador, vinculado a uma localização |
| `tb_ocorrencia` | problema urbano reportado, com status e data de resolução |
| `tb_monitoramento_ambiental` | medição de poluição e qualidade do ar |
| `tb_servico_limpeza` | serviço de limpeza agendado |
| `tb_alerta` | notificação gerada para um usuário |
 
A localização é o eixo do modelo: é por ela que o sistema descobre **quem avisar** quando algo
acontece em um bairro.
 
## Procedures
 
| Procedure | O que faz |
|---|---|
| `sp_verificar_ou_registrar_localizacao` | devolve o id de uma localização, criando-a se ainda não existir |
| `sp_inserir_usuario_e_localizacao` | resolve a localização e insere o usuário |
| `sp_inserir_ocorrencia_e_localizacao` | resolve a localização, busca o usuário por nome e e-mail, e insere a ocorrência com status `Em Andamento` |
| `sp_inserir_monitoramento_e_localizacao` | resolve a localização e insere a medição ambiental |
| `sp_inserir_servico_limpeza_e_localizacao` | resolve a localização e insere o serviço |
 
As quatro últimas são variações da mesma ideia: **quem registra um fato não precisa saber se o
endereço dele já existe no banco.**
 
## Triggers
 
| Trigger | Quando dispara | O que faz |
|---|---|---|
| `tr_alerta_ocorrencia` | após `INSERT` ou `UPDATE` em `tb_ocorrencia` | cria um alerta para cada usuário do mesmo bairro da ocorrência |
| `tr_notifica_coleta_lixo` | após `INSERT` em `tb_servico_limpeza` | cria um alerta para cada usuário do bairro atendido |
| `tr_verificar_permissao_atualizacao` | antes de `UPDATE` da coluna `status_ocorrencia` | bloqueia a alteração quando o autor da ocorrência é trocado por um usuário que não é `Admin` |
 
## Decisões técnicas
 
**A resolução de endereço é responsabilidade de uma procedure, não de quem insere.**
 
Sem isso, cada ponto do sistema que registra uma ocorrência, uma medição ou um serviço
precisaria repetir a lógica de "este endereço já existe? se não, crie" — e as cópias
divergiriam. Escolhi concentrar numa procedure com parâmetro `OUT` em vez de deixar a cargo do
chamador, porque é uma pré-condição do registro e não uma decisão de quem registra. As quatro
procedures de entrada chamam essa mesma.
 
O custo é um nível de indireção: quem lê o `insert` da ocorrência não vê a criação do endereço
acontecendo.
 
**O "endereço não encontrado" é tratado como caminho normal, via `NO_DATA_FOUND`.**
 
Um `SELECT ... INTO` que não acha nada lança exceção em PL/SQL; não há como "não achar" em
silêncio. Escolhi tratar no `EXCEPTION` e inserir ali, em vez de fazer um `SELECT COUNT(*)`
antes para decidir, porque a segunda forma consulta a tabela duas vezes para responder à mesma
pergunta.
 
O custo é usar exceção como fluxo de controle, o que em outras linguagens seria criticado — em
PL/SQL é idiomático, mas quem vem de Java estranha.
 
**As notificações são disparadas por trigger, e não pela aplicação.**
 
O evento que importa é a linha entrar na tabela, e quem enxerga esse evento sem exceção é o
banco: uma ocorrência registrada por script de carga ou por outro sistema também notifica.
 
O custo é real e vale registrar: lógica de notificação dentro do banco é mais difícil de testar,
de observar e de desligar do que na aplicação. Num sistema maior eu publicaria o evento e
deixaria a notificação fora do banco.
 
## O que eu mudaria hoje
 
Este projeto é de 2024. Relendo o script agora, cinco pontos que eu trataria de outra forma — e
o primeiro é o mais interessante.
 
**1. O trigger de permissão não sabe quem está agindo.**
`tb_ocorrencia.id_usuario` é quem *registrou* a ocorrência, não quem está executando o `UPDATE`.
A comparação `:NEW.id_usuario <> :OLD.id_usuario` só detecta a troca de autor; um update de
status que não mexa nessa coluna passa, venha de quem vier. A causa é estrutural: um trigger
enxerga linhas, não atores. O banco conhece a sessão, mas a aplicação conecta com um usuário
técnico único — para o Oracle, todos os moradores são a mesma pessoa. Para aplicar autorização
aqui seria preciso **informar** o ator: contexto de aplicação, variável de package, ou fazer o
update passar por uma procedure que o receba como parâmetro.
 
**2. Falta `unique` nas colunas de endereço.**
`sp_verificar_ou_registrar_localizacao` consulta, não encontra, e insere. Duas sessões
simultâneas fazem a consulta antes de qualquer inserção e gravam o mesmo endereço duas vezes.
A verificação em código não fecha a janela; só uma restrição no schema fecha, porque só o banco
serializa. É a mesma falha que encontrei depois em outro projeto, e a lição é a mesma.
 
**3. O alerta de coleta usa um id de ocorrência inventado.**
`tr_notifica_coleta_lixo` insere `id_ocorrencia = 9999` fixo, mas `tb_alerta.id_ocorrencia` é
`NOT NULL` com chave estrangeira. Isso é o modelo avisando que está errado: um alerta de coleta
não é sobre uma ocorrência. A correção é no modelo, não no trigger — a coluna deveria aceitar
nulo, ou `tb_alerta` deveria ter um tipo e referenciar a origem conforme o caso.
 
**4. A sequence compartilhada tem prazo de validade.**
`seq_id` serve todas as tabelas com `MINVALUE 1000 MAXVALUE 9999 CYCLE`. Somadas cerca de nove
mil inserções, ela volta para 1000 e passa a colidir com chaves existentes. O `CYCLE` existe
porque as colunas são `NUMBER(4)` — uma escolha de largura de tipo que virou limite de vida útil
do sistema.
 
**5. As procedures dão `COMMIT`.**
Isso tira do chamador a decisão de onde a transação termina: quem quiser inserir um usuário e
mais alguma coisa de forma atômica não consegue. Procedure de escrita não deveria commitar —
deveria deixar a fronteira da transação para quem a chamou.
 
## Contexto acadêmico
 
Desenvolvido na FIAP, no curso de Análise e Desenvolvimento de Sistemas, como a etapa de banco
de dados do projeto CityCare. O objetivo era exercitar programação orientada a eventos dentro do
banco — triggers, procedures e modelagem — aplicada a um domínio de cidades inteligentes.
 
