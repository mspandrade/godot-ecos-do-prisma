# Plano revisado do jogo com visão profissional de game dev

## 1. Visão geral do projeto

O jogo será um RPG de gerenciamento de guilda com combate autoshooter em visão isométrica, desenvolvido na Godot Engine.

A ideia central é forte porque mistura três fantasias de jogo:

1. Ser o líder de uma guilda falida que cresce aos poucos.
2. Montar e evoluir um esquadrão de companions.
3. Sobreviver a hordas de monstros em combate automático estilo Vampire Survivors.

O diferencial está no protagonista: ele sonha em derrotar o Rei Demônio, mas não sabe lutar. Em vez de virar um herói tradicional, ele precisa construir uma guilda poderosa, recrutar companions, treiná-los, equipá-los e comandá-los estrategicamente.

---

## 2. Pitch refinado

Você não é o escolhido.
Você não sabe lutar.
Você não possui magia, espada lendária ou bênção divina.

Mesmo assim, seu sonho é derrotar o Rei Demônio.

Com o último dinheiro deixado por seu avô, você compra uma guilda falida e começa a recrutar aventureiros dispostos a lutar em seu nome. Treine companions, equipe seu esquadrão, enfrente hordas infinitas de monstros, fuja quando necessário e transforme uma guilda esquecida no maior exército de aventureiros do mundo.

---

## 3. Gênero do jogo

### Gênero principal

Autoshooter isométrico com gerenciamento de guilda.

### Subgêneros

- RPG de progressão.
- Gerenciamento de equipe.
- Roguelite leve.
- Estratégia tática indireta.
- Sobrevivência contra hordas.
- Base management.

---

## 4. Pilares de design

### Pilar 1 — O jogador é um líder, não um guerreiro

O protagonista não deve ser tratado como personagem de combate. A fantasia principal é comandar, preparar e evoluir outros personagens.

O jogador vence por:

- Boa composição de esquadrão.
- Escolha certa de companions.
- Treinamento eficiente.
- Gerenciamento de moedas.
- Decisões de risco.
- Saber quando fugir.
- Evoluir corretamente a guilda.

### Pilar 2 — Companions são valiosos

Cada companion precisa parecer importante. O jogador deve sentir que está formando uma equipe, não apenas usando unidades descartáveis.

Cada companion deve ter:

- Nome.
- Classe.
- Raridade.
- Atributos.
- Habilidades.
- Traços.
- Equipamentos.
- Estado físico.
- Level.
- Histórico.
- Risco de morte.

A morte de um companion deve ter peso emocional e mecânico.

### Pilar 3 — Combate simples de jogar, difícil de dominar

O combate deve ser acessível: o jogador movimenta o grupo e os companions atacam automaticamente.

A profundidade vem de:

- Formação do esquadrão.
- Velocidade média do grupo.
- Habilidades automáticas.
- Posicionamento.
- Fuga.
- Coleta de recursos.
- Sobrevivência em waves.
- Escolha de upgrades ao subir de level.

### Pilar 4 — Risco e recompensa

Quanto mais tempo o jogador permanece em uma zona perigosa, maiores são as recompensas, mas maior também é o risco de morte.

O jogador deve se perguntar constantemente:

“Continuo mais um pouco ou fujo agora para salvar meu time?”

Essa decisão é essencial para a identidade do jogo.

---

## 5. Direção visual

### Visão isométrica

O jogo deve usar visão isométrica 2D, idealmente com pixel art ou arte 2D estilizada.

A visão isométrica será usada em:

- Guilda.
- Zonas de combate.
- Personagens.
- Monstros.
- Objetos de cenário.
- Estruturas.
- Portais.
- Cemitério.
- Campo de treinamento.

### Estilo recomendado

O estilo ideal seria pixel art isométrico medieval-fantasia, com leitura clara dos personagens e inimigos.

Referências de sensação visual:

- Guilda aconchegante, mas decadente no início.
- Florestas, cavernas, cemitérios e ruínas com atmosfera sombria.
- Efeitos de ataque bem visíveis.
- Silhuetas fortes para cada classe.
- Inimigos fáceis de reconhecer mesmo em grande quantidade.

---

## 6. Plataforma e engine

### Engine

O jogo será desenvolvido na Godot Engine.

### Recomendação técnica

Para esse projeto, a Godot combina bem porque permite trabalhar com:

- Cenas reutilizáveis.
- Sistema de nós.
- UI integrada.
- 2D forte.
- Tilemaps.
- Recursos customizados.
- Salvamento local.
- Controle de spawns.
- Combate em tempo real.

---

## 7. Estrutura geral do jogo

O jogo será dividido em dois grandes modos:

### 1. Modo Guilda

É onde o jogador gerencia tudo.

Funções:

- Recrutar companions.
- Rolar fila de recrutamento.
- Treinar companions.
- Equipar personagens.
- Evoluir guilda.
- Escolher missões.
- Ressuscitar mortos.
- Gerenciar esquadrão.
- Ver moedas, reputação e progresso.

### 2. Modo Combate

É onde o jogador leva o esquadrão para zonas perigosas.

Funções:

- Movimentar o grupo.
- Sobreviver a waves.
- Coletar moedas e XP.
- Enfrentar elites e chefes.
- Fugir.
- Proteger companions caídos.
- Retornar à guilda com recompensas.

---

## 8. Loop principal refinado

O loop principal deve ser simples e viciante:

1. Jogador está na guilda.
2. Verifica moedas, companions e missões.
3. Recruta ou rola novos companions.
4. Treina e equipa o time.
5. Monta esquadrão de até 6 companions.
6. Confere risco, level médio e velocidade média.
7. Entra em uma zona isométrica.
8. Sobrevive a hordas de inimigos.
9. Coleta moedas, XP e itens.
10. Decide continuar ou fugir.
11. Retorna à guilda.
12. Companions sobem de level.
13. Jogador escolhe atributos ou poderes.
14. Guilda evolui.
15. Novas zonas são desbloqueadas.
16. O ciclo se repete até o Rei Demônio.

---

## 9. Sistema de companions

Os companions são o coração do jogo.

### Dados principais de cada companion

| Campo | Função |
|---|---|
| Nome | Identidade do personagem |
| Classe | Define estilo de combate |
| Raridade | Define potencial e opções raras |
| Level | Progressão individual |
| XP | Experiência acumulada |
| Vida | Sobrevivência |
| Ataque | Dano causado |
| Defesa | Redução de dano |
| Velocidade | Afeta velocidade média do grupo |
| Alcance | Distância de ataque |
| Crítico | Chance de dano crítico |
| Sorte | Influencia drops e eventos |
| Habilidade ativa | Poder principal |
| Passiva | Bônus constante |
| Traços | Características positivas/negativas |
| Equipamentos | Itens usados |
| Estado | Disponível, ferido, caído, morto etc. |

---

## 10. Classes iniciais recomendadas

Para o MVP, não comece com muitas classes. Use 6 classes bem definidas.

### Guerreiro

Função: combate corpo a corpo equilibrado.

Características:

- Boa vida.
- Bom dano próximo.
- Defesa média.
- Fácil de entender.

Habilidade inicial:

Golpe Largo — atinge inimigos em arco à frente.

### Tanque

Função: proteger o grupo.

Características:

- Muita vida.
- Alta defesa.
- Baixa velocidade.
- Baixo dano.

Habilidade inicial:

Provocar — atrai inimigos próximos.

### Arqueiro

Função: dano à distância.

Características:

- Bom alcance.
- Boa velocidade de ataque.
- Baixa defesa.

Habilidade inicial:

Tiro Duplo — dispara duas flechas.

### Mago

Função: dano em área.

Características:

- Alto dano mágico.
- Baixa vida.
- Excelente contra hordas.

Habilidade inicial:

Bola de Fogo — explode ao atingir inimigos.

### Curandeiro

Função: suporte e sobrevivência.

Características:

- Cura aliados.
- Baixo dano.
- Essencial em missões longas.

Habilidade inicial:

Cura Leve — cura o aliado com menor vida.

### Assassino

Função: eliminar elites.

Características:

- Alta velocidade.
- Alto crítico.
- Pouca defesa.
- Bom contra inimigos prioritários.

Habilidade inicial:

Investida Sombria — avança até um alvo e causa dano alto.

---

## 11. Esquadrão

O jogador poderá montar um esquadrão com até 6 companions ativos.

Esse limite é bom porque força decisões estratégicas.

Exemplos de composição:

### Time equilibrado

- Tanque.
- Guerreiro.
- Arqueiro.
- Mago.
- Curandeiro.
- Assassino.

### Time defensivo

- Tanque.
- Guerreiro.
- Curandeiro.
- Bardo futuramente.
- Mago.
- Arqueiro.

### Time rápido

- Assassino.
- Arqueiro.
- Arqueiro.
- Curandeiro.
- Mago.
- Guerreiro leve.

---

## 12. Velocidade média do esquadrão

A movimentação do grupo depende da velocidade média dos companions ativos.

Isso é uma ótima mecânica porque transforma velocidade em decisão estratégica.

### Exemplo

| Companion | Velocidade |
|---|---:|
| Tanque | 3 |
| Arqueiro | 7 |
| Mago | 5 |
| Curandeiro | 5 |
| Assassino | 9 |
| Guerreiro | 6 |

Cálculo:

3 + 7 + 5 + 5 + 9 + 6 = 35

35 ÷ 6 = 5,8

Velocidade média: 5,8

### Classificação exibida ao jogador

| Velocidade média | Classificação |
|---:|---|
| 0 a 3,9 | Muito lento |
| 4 a 5,9 | Lento |
| 6 a 7,4 | Equilibrado |
| 7,5 a 8,9 | Rápido |
| 9+ | Muito rápido |

Antes de iniciar uma missão, o jogo deve mostrar:

Velocidade média do esquadrão: 5,8 — Lento

E também um aviso:

Este esquadrão pode ter dificuldade para fugir de hordas rápidas.

---

## 13. Combate autoshooter isométrico

### Funcionamento

Durante o combate:

- O jogador movimenta o grupo.
- Companions atacam automaticamente.
- Inimigos aparecem em ondas.
- XP e moedas caem no mapa.
- O jogador coleta recursos ao se aproximar.
- Companions podem cair.
- O jogador pode fugir.
- Waves ficam mais difíceis com o tempo.

### Controle recomendado

Como o jogo será isométrico, a movimentação precisa ser bem ajustada.

Em jogos isométricos, o input do jogador deve ser convertido para movimento diagonal no mundo.

Exemplo:

- Cima move o grupo para nordeste.
- Baixo move para sudoeste.
- Esquerda move para noroeste.
- Direita move para sudeste.

O importante é que o movimento pareça natural, fluido e responsivo.

---

## 14. Sistema de waves

As waves devem criar pressão crescente.

### Exemplo de progressão em uma zona

| Tempo | Evento |
|---|---|
| 0:00 | Inimigos fracos aparecem |
| 1:30 | Mais inimigos por wave |
| 3:00 | Inimigos rápidos surgem |
| 5:00 | Primeiro elite |
| 8:00 | Inimigos resistentes |
| 10:00 | Mini-chefe |
| 15:00 | Horda intensa |
| 20:00 | Chefe da zona |

Quanto mais tempo o jogador fica, melhores os drops.

---

## 15. Fuga

A fuga é uma mecânica importante e deve ser tratada como estratégia, não como derrota.

### Quando o jogador foge

Pode acontecer:

- Perda parcial de moedas.
- Perda de parte do XP coletado.
- Missão considerada incompleta.
- Companions caídos podem correr risco.
- O grupo retorna para a guilda.

### Velocidade influencia fuga

Esquadrões rápidos devem fugir com mais segurança.

| Velocidade | Chance de fuga segura |
|---|---|
| Muito lento | Baixa |
| Lento | Média-baixa |
| Equilibrado | Média |
| Rápido | Alta |
| Muito rápido | Muito alta |

---

## 16. Sistema de morte

A morte precisa ser impactante, mas justa.

### Fluxo recomendado

1. Companion perde toda a vida.
2. Entra no estado caído.
3. Um contador aparece.
4. O jogador pode tentar sobreviver até a recuperação ou fugir.
5. Se o contador acabar, o companion morre.
6. O companion vai para o cemitério.
7. Pode ser ressuscitado com custo.

### Estados dos companions

| Estado | Descrição |
|---|---|
| Disponível | Pode ser usado |
| Treinando | Está no campo de treinamento |
| Em missão | Está em combate |
| Ferido | Sofreu penalidade temporária |
| Caído | Pode morrer se não for salvo |
| Morto | Está no cemitério |
| Ressuscitado | Voltou com penalidade temporária |

---

## 17. Cemitério

O cemitério é uma excelente mecânica para reforçar a importância dos companions.

### Funções

- Guardar histórico dos companions mortos.
- Permitir ressurreição.
- Mostrar causa da morte.
- Aplicar penalidades de retorno.
- Criar apego emocional.

### Ressurreição

Pode exigir:

- Moedas.
- Cristal de alma.
- Tempo de recuperação.
- Level mínimo da guilda.
- Upgrade do cemitério.

### Penalidades possíveis

- Perda de XP.
- Redução temporária de atributos.
- Estado “traumatizado”.
- Menor moral.
- Menor velocidade por uma missão.
- Maldição leve.

---

## 18. Recrutamento aleatório

A guilda terá uma fila de recrutamento.

### Funcionamento

O jogador verá uma lista de candidatos.

Cada candidato possui:

- Nome.
- Classe.
- Raridade.
- Level inicial.
- Custo.
- Atributos.
- Traço.
- Habilidade inicial.

O jogador pode contratar ou gastar moedas para rolar a fila.

### Reroll

O reroll troca os candidatos disponíveis.

| Reroll | Custo sugerido |
|---:|---:|
| 1º | 100 moedas |
| 2º | 150 moedas |
| 3º | 250 moedas |
| 4º | 400 moedas |

O custo deve resetar após:

- Retornar de uma missão.
- Passar um ciclo de jogo.
- Subir o nível da guilda.

### Chances de raridade

| Raridade | Chance inicial |
|---|---:|
| Comum | 60% |
| Incomum | 25% |
| Raro | 10% |
| Épico | 4% |
| Lendário | 1% |

Melhorias da guilda aumentam chances de recrutas raros.

---

## 19. Evolução ao subir de level

Quando um companion sobe de level, o jogador escolhe uma melhoria.

Essa escolha é essencial para criar apego e personalização.

### Opções possíveis

- Aumentar vida.
- Aumentar ataque.
- Aumentar defesa.
- Aumentar velocidade.
- Aumentar alcance.
- Aumentar crítico.
- Aumentar sorte.
- Melhorar habilidade.
- Ganhar nova passiva.
- Ganhar poder especial.

### Raridade influencia evolução

| Raridade | Opções ao upar | Qualidade das opções |
|---|---:|---|
| Comum | 3 | Simples |
| Incomum | 3 | Simples com chance de passiva |
| Raro | 4 | Boas opções e poderes |
| Épico | 4 | Poderes fortes |
| Lendário | 5 | Poderes únicos |

### Marcos de evolução

| Level | Recompensa |
|---:|---|
| 2 | Atributo básico |
| 3 | Atributo básico |
| 5 | Nova habilidade ou melhoria forte |
| 10 | Especialização |
| 15 | Poder avançado |
| 20 | Habilidade definitiva |

---

## 20. Equipamentos

Equipamentos devem reforçar estratégia, não apenas aumentar números.

### Tipos

- Espadas.
- Arcos.
- Cajados.
- Escudos.
- Armaduras.
- Botas.
- Amuletos.
- Anéis.

### Efeitos

- Mais ataque.
- Mais defesa.
- Mais vida.
- Mais crítico.
- Mais alcance.
- Mais velocidade.
- Mais sorte.
- Resistência elemental.

### Atenção importante

Equipamentos devem afetar a velocidade média do esquadrão.

Exemplo:

- Armadura pesada: +defesa, -velocidade.
- Botas leves: +velocidade.
- Escudo gigante: +defesa, -velocidade.
- Amuleto do vento: +10% velocidade.

Isso evita escolhas óbvias e força balanceamento.

---

## 21. Guilda

A guilda é a base central do jogo.

### Estruturas principais

| Estrutura | Função |
|---|---|
| Salão principal | Gerenciamento geral |
| Quadro de missões | Escolher zonas e contratos |
| Recrutamento | Fila de companions |
| Dormitórios | Guardar companions |
| Campo de treinamento | Melhorar atributos |
| Ferreiro | Comprar e melhorar equipamentos |
| Cemitério | Ressuscitar mortos |
| Portal | Fast travel |
| Armazém | Guardar itens |

### Evolução da guilda

| Level | Desbloqueios |
|---:|---|
| 1 | Recrutamento básico, missões simples |
| 2 | Campo de treinamento, mais espaço |
| 3 | Cemitério, ferreiro, fast travel |
| 4 | Recrutas raros, equipamentos melhores |
| 5 | Missões especiais e preparação contra o Rei Demônio |

---

## 22. Salvamento automático

O jogo terá salvamento automático.

Não haverá dependência de save manual.

### Momentos de auto-save

O jogo deve salvar quando:

- Jogador retorna para a guilda.
- Missão termina.
- Jogador foge.
- Companion morre.
- Companion é ressuscitado.
- Companion sobe de level.
- Jogador escolhe upgrade.
- Companion é recrutado.
- Fila é rolada.
- Equipamento é comprado.
- Guilda é melhorada.
- Nova zona é desbloqueada.

### Feedback visual

Mostrar discretamente:

Salvando...
Progresso salvo.

Isso evita insegurança do jogador.

---

## 23. Zonas e progressão

O jogo terá várias zonas isométricas.

### Exemplo de progressão

| Zona | Level recomendado |
|---|---:|
| Floresta Inicial | 1 |
| Caverna dos Lobos | 3 |
| Ruínas Antigas | 5 |
| Pântano Venenoso | 8 |
| Cemitério Maldito | 10 |
| Fortaleza Demoníaca | 15 |
| Castelo do Rei Demônio | 25 |

Cada zona deve ter:

- Tema visual.
- Inimigos próprios.
- Recompensas próprias.
- Risco específico.
- Possível chefe.
- Level recomendado.
- Materiais únicos.

---

## 24. Missões

As missões dão objetivos além de sobreviver.

### Tipos de missão

- Sobreviver por tempo.
- Eliminar quantidade de inimigos.
- Derrotar mini-chefe.
- Coletar recursos.
- Resgatar NPC.
- Defender ponto.
- Proteger caravana.
- Explorar zona.
- Caçar monstro raro.

---

## 25. Fast travel

O fast travel deve ser desbloqueado progressivamente.

Pode exigir:

- Chegar à zona uma vez.
- Ativar portal.
- Derrotar chefe local.
- Pagar moedas.
- Melhorar a guilda.

Não deve funcionar durante combate.

---

## 26. Interface e UX

A interface precisa deixar as informações estratégicas muito claras.

Antes de iniciar uma missão, o jogador deve ver:

- Level recomendado da zona.
- Level médio do esquadrão.
- Velocidade média.
- Classificação de velocidade.
- Risco de morte.
- Recompensas possíveis.
- Inimigos principais.
- Aviso se o time estiver fraco.

Exemplo:

Zona: Cemitério Maldito
Level recomendado: 10
Level médio do esquadrão: 8
Velocidade média: 5.4 — Lento
Risco: Alto

Aviso:
Seu esquadrão está abaixo do level recomendado e possui baixa mobilidade.
Fugir pode ser difícil.

---

## 27. Arquitetura técnica sugerida na Godot

### Cenas principais

| Cena | Função |
|---|---|
| GuildScene | Tela/base da guilda |
| CombatScene | Combate isométrico |
| Companion.tscn | Companion em combate |
| Enemy.tscn | Inimigo base |
| Projectile.tscn | Projéteis |
| DropItem.tscn | Moedas, XP e itens |
| RecruitmentUI.tscn | Recrutamento |
| SquadUI.tscn | Montagem do esquadrão |
| LevelUpUI.tscn | Escolha de evolução |
| GraveyardUI.tscn | Cemitério |
| MissionSelectUI.tscn | Escolha de missão |

### Autoloads recomendados

| Autoload | Função |
|---|---|
| GameManager | Estado geral do jogo |
| SaveManager | Auto-save e load |
| GuildManager | Dados da guilda |
| CompanionManager | Lista e estados dos companions |
| RecruitmentManager | Fila de recrutamento |
| MissionManager | Missões e zonas |
| AudioManager | Música e efeitos |
| BalanceDatabase | Dados de atributos, raridades e custos |

---

## 28. Dados principais

### Companion

CompanionData
- id
- nome
- classe
- raridade
- level
- xp
- vidaMaxima
- vidaAtual
- ataque
- defesa
- velocidade
- alcance
- critico
- sorte
- habilidadeAtiva
- passiva
- tracos
- equipamentos
- estado

### Guilda

GuildData
- nome
- level
- moedas
- reputacao
- capacidadeCompanions
- companionsContratados
- companionsMortos
- estruturasDesbloqueadas
- zonasDesbloqueadas

### Esquadrão

SquadData
- companionsSelecionados
- levelMedio
- velocidadeMedia
- poderTotal
- riscoAtual

### Missão

MissionData
- id
- nome
- zona
- levelRecomendado
- recompensaMoedas
- recompensaXP
- inimigos
- chefe
- risco
- desbloqueada

### Recrutamento

RecruitmentData
- recrutasDisponiveis
- custoReroll
- contadorReroll
- chancesRaridade

### Save

SaveData
- versao
- dataUltimoSave
- guilda
- companions
- inventario
- missoes
- zonasDesbloqueadas
- configuracoes

---

## 29. Ordem profissional de desenvolvimento

### Fase 1 — Prova de conceito

Objetivo: validar se o combate funciona.

Entregas:

- Movimento isométrico do grupo.
- Câmera seguindo o esquadrão.
- Companions atacando automaticamente.
- Inimigos surgindo.
- Sistema simples de vida e dano.
- Coleta de moedas.

### Fase 2 — MVP de combate

Objetivo: criar uma batalha completa.

Entregas:

- 3 classes jogáveis.
- 3 tipos de inimigos.
- Waves.
- XP.
- Moedas.
- Fuga.
- Vitória ou retorno à guilda.

### Fase 3 — Sistema de companions

Objetivo: transformar unidades em personagens persistentes.

Entregas:

- Atributos.
- Level.
- XP.
- Estado.
- Raridade.
- Habilidades.
- Tela de companions.

### Fase 4 — Guilda funcional

Objetivo: fechar o loop principal.

Entregas:

- Tela da guilda.
- Lista de companions.
- Tela de missões.
- Retorno após combate.
- Auto-save.

### Fase 5 — Recrutamento

Objetivo: permitir crescimento do exército.

Entregas:

- Fila aleatória.
- Reroll com moedas.
- Custo de contratação.
- Raridades.
- Auto-save após recrutamento.

### Fase 6 — Level up com escolhas

Objetivo: adicionar personalização.

Entregas:

- Tela de level up.
- Escolha de atributo.
- Poderes por raridade.
- Marcos de level.
- Impacto na velocidade média.

### Fase 7 — Morte e cemitério

Objetivo: adicionar peso estratégico.

Entregas:

- Estado caído.
- Morte.
- Cemitério.
- Ressurreição.
- Penalidades.
- Auto-save.

### Fase 8 — Equipamentos e treinamento

Objetivo: aumentar profundidade.

Entregas:

- Itens equipáveis.
- Modificadores de atributos.
- Campo de treinamento.
- Penalidades de velocidade.
- Melhorias permanentes.

### Fase 9 — Conteúdo

Objetivo: transformar o protótipo em jogo.

Entregas:

- Mais zonas.
- Mais inimigos.
- Chefes.
- Missões.
- Fast travel.
- Evolução da guilda.
- Progressão até o Rei Demônio.

---

## 30. MVP recomendado

O MVP ideal deve conter:

- Godot.
- Visão isométrica.
- 1 zona inicial.
- 1 guilda básica.
- 6 companions possíveis.
- 3 companions iniciais.
- Esquadrão de até 6.
- 4 classes iniciais no mínimo.
- 3 tipos de inimigos.
- 1 elite.
- Waves por tempo.
- Moedas.
- XP.
- Level up com escolha de atributo.
- Recrutamento com reroll.
- Velocidade média.
- Fuga.
- Morte.
- Cemitério simples.
- Auto-save.

Esse MVP já mostraria a identidade completa do jogo.

---

## 31. Riscos de design e soluções

### Risco 1 — Morte permanente frustrante

Solução:

- Usar estado caído antes da morte.
- Permitir fuga.
- Permitir ressurreição.
- Dar avisos claros de risco.

### Risco 2 — Velocidade média punir demais tanques

Solução:

- Tanques podem ter habilidades de proteção que compensam lentidão.
- Equipamentos podem melhorar velocidade.
- Algumas zonas podem favorecer times lentos e defensivos.

### Risco 3 — Reroll virar cassino excessivo

Solução:

- Limitar custo crescente.
- Resetar após missão.
- Permitir recrutas bons mesmo sem reroll.
- Dar opções viáveis comuns e incomuns.

### Risco 4 — Muitos sistemas cedo demais

Solução:

- Primeiro fazer combate divertido.
- Depois companions.
- Depois guilda.
- Depois cemitério, equipamentos e sistemas avançados.

### Risco 5 — Tela poluída no autoshooter

Solução:

- Efeitos visuais simples.
- Silhuetas claras.
- Barras de vida pequenas.
- Ícones limpos.
- Poucas informações durante combate.
- Informações complexas ficam na guilda.

---

## 32. Priorização final

### Essencial

- Movimento isométrico.
- Combate autoshooter.
- Companions.
- Esquadrão.
- Velocidade média.
- Moedas.
- XP.
- Level up.
- Guilda.
- Recrutamento.
- Fuga.
- Morte.
- Auto-save.

### Importante

- Cemitério.
- Ressurreição.
- Equipamentos.
- Treinamento.
- Zonas.
- Missões.
- Fast travel.
- Evolução da guilda.

### Futuro

- Moral.
- Afinidade.
- Falas.
- Eventos aleatórios.
- Classes avançadas.
- Chefes complexos.
- História em atos.
- Ataques à guilda.
- Rei Demônio final.

---

## 33. Visão final revisada

O jogo será um autoshooter isométrico em Godot com gerenciamento de guilda, onde o jogador controla um líder sem habilidades de combate que precisa construir um exército de companions para derrotar o Rei Demônio.

A experiência principal será baseada em preparação, risco e consequência.

O jogador recruta companions em uma fila aleatória, gasta moedas para rolar novos candidatos, monta um esquadrão de até 6 membros, avalia velocidade média e risco da missão, entra em zonas perigosas com hordas infinitas, coleta recompensas, foge quando necessário e retorna para a guilda para evoluir.

Cada companion pode subir de level, escolher atributos, ganhar poderes de acordo com sua raridade, usar equipamentos, morrer, ser ressuscitado e se tornar parte importante da história da guilda.

O salvamento será automático, mantendo o fluxo do jogo sem interromper o jogador.

A jornada começa com uma guilda falida.

O objetivo final é construir uma organização poderosa o bastante para fazer aquilo que o protagonista jamais conseguiria sozinho:

derrotar o Rei Demônio.
