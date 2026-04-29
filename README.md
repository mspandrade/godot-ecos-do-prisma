# Iso Survival Prototype



Prototipo de jogo mobile em Godot Engine 4.x com visao isometrica, progressao durante a run e combate automatico. O jogador controla apenas o movimento por toque, enquanto armas, aliados e efeitos de combate funcionam de forma automatica.

## Conceito

O jogo segue um loop de sobrevivencia automatica:

1. mover pelo mapa;
2. evitar hordas de inimigos;
3. coletar XP;
4. subir de nivel;
5. escolher upgrades;
6. recrutar companheiros perdidos;
7. tentar sobreviver cada vez mais tempo.

O foco e criar uma experiencia simples de controlar no celular, mas com decisoes estrategicas de build e crescimento gradual de poder.

## Controles

- Mobile: joystick virtual por toque.
- Editor/PC: clique e arraste com o mouse como fallback de teste.
- O teclado nao e usado para movimentacao.

## Sistemas Implementados

### Player

- Movimento isometrico adaptado.
- Camera seguindo suavemente.
- Vida com barra no HUD.
- Intangibilidade por 1,5s apos tomar dano, removendo temporariamente a colisao.
- Ataques automaticos via sistema de armas.

### Combate

Armas automaticas disponiveis:

- projetil direcional;
- aura de dano;
- arma orbital;
- ataque em area.

As armas possuem cooldown, dano, upgrades e evolucao combinada com passivos.

### Progressao da Run

- Inimigos dropam orbs de XP.
- Level up abre 3 escolhas aleatorias.
- Limite de 6 armas e 6 passivos.
- Passivos incluem dano, velocidade, alcance de coleta, vida maxima, reducao de dano e regeneracao.

### Companheiros

Os companheiros nao comecam na party. Eles aparecem perdidos pelo mapa e precisam ser recrutados pelo player ao se aproximar.

Classes:

- Guerreiro do Escudo: faz uma investida curta, fica invulneravel durante a ida e a volta, causa dano e empurra inimigos.
- Mago: ataca em area e aplica queimadura.
- Arqueiro: atira em inimigos a distancia.
- Bardo: aplica buff temporario de dano e velocidade no player.

Companheiros:

- tem vida propria;
- aparecem no HUD apenas apos recrutados;
- podem subir de nivel;
- recebem upgrades escolhidos pelo jogador;
- morrem definitivamente durante a run.

### Inimigos

- Spawn continuo ao redor do jogador.
- Mais inimigos no inicio da partida.
- Ondas com dificuldade progressiva.
- Chefes periodicos.
- Inimigos perseguem o heroi vivo mais proximo, incluindo player e companheiros recrutados.

### Meta Progressao

- Moedas acumuladas.
- Loja de upgrades permanentes.
- Desbloqueio e selecao de personagens.
- Melhorias persistentes de vida, dano, velocidade e alcance de coleta.

## Estrutura

Principais cenas:

- `scenes/ui/MainMenu.tscn`
- `scenes/Game.tscn`
- `scenes/Player.tscn`
- `scenes/Enemy.tscn`
- `scenes/Companion.tscn`
- `scenes/Projectile.tscn`
- `scenes/XPOrb.tscn`

Principais scripts:

- `scripts/game/game_manager.gd`
- `scripts/game/player.gd`
- `scripts/game/companion.gd`
- `scripts/game/companion_manager.gd`
- `scripts/game/enemy.gd`
- `scripts/game/enemy_spawner.gd`
- `scripts/game/weapon_system.gd`
- `scripts/game/upgrade_manager.gd`
- `scripts/core/game_data.gd`
- `scripts/core/run_state.gd`

## Como Rodar

Abra a pasta do projeto no Godot 4.x e execute a cena principal:

```text
res://scenes/ui/MainMenu.tscn
```

Ou rode pela linha de comando:

```powershell
godot --path .
```

## Testes

O projeto inclui uma suite simples de testes em GDScript:

```powershell
godot --headless --path . --script res://tests/test_runner.gd
```

Validacao rapida da cena de jogo:

```powershell
godot --headless --path . --scene res://scenes/Game.tscn --quit-after 8
```

## Estado Atual

Este e um prototipo funcional com placeholders visuais simples. Ainda ha espaco para evoluir arte, audio, balanceamento fino, efeitos, telemetria, mapa, objetivos secundarios e exportacao mobile.
