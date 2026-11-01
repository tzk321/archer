// src/player.js
import Arrow from "./arrow.js"

export default class Player {
  constructor(scene, x, y, key) {
    this.scene = scene
    this.player = scene.add.image(x, y, key).setScale(0.15)
    this.arrowCooldown = 1000
    this.lastArrowTime = 0

    // Criar o hitbox oval para o jogador
    this.hitbox = scene.add.ellipse(x, y, 60, 80, 0x808080, 0)
    this.hitbox.setOrigin(0.5, 0.5)

    // Vida do jogador - valores iniciais salvos
    this.initialHealth = 2000
    this.initialMaxHealth = 2000
    this.health = this.initialHealth
    this.maxHealth = this.initialMaxHealth

    // Propriedades de poder - valores iniciais salvos
    this.initialArrowDamage = 200
    this.initialMovementSpeed = 3
    this.initialMultiArrow = 1
    this.initialArrowCooldown = 1000

    this.arrowDamage = this.initialArrowDamage
    this.movementSpeed = this.initialMovementSpeed
    this.multiArrow = this.initialMultiArrow

    // Controle de movimento
    this.canMove = true

    // Barra de vida
    this.healthBar = this.scene.add.graphics()
    this.updateHealthBar()

    // Valor da vida
    this.healthText = this.scene.add.text(this.player.x - 20, this.player.y - 60, `${this.health}/${this.maxHealth}`, {
      fontSize: "18px",
      fill: "#ffffff",
      fontStyle: "bold",
      stroke: "#000000",
      strokeThickness: 4,
    })

    // Variáveis de controle de invencibilidade (para receber dano)
    this.invincibleTime = 0
    this.invincibleDuration = 1000

    // Variáveis de controle de cooldown para CAUSAR dano de colisão
    this.lastCollisionDamageTime = 0
    this.collisionDamageCooldown = 800 // 800ms entre cada dano de colisão que o player causa

    // Variáveis de controle de cooldown para dano do player (mantido para compatibilidade)
    this.lastDamageTime = 0
    this.damageCooldown = 1000

    // Teclas de controle (WASD + setas)
    this.cursors = this.scene.input.keyboard.createCursorKeys()
    this.keys = {
      up: this.scene.input.keyboard.addKey("W"),
      down: this.scene.input.keyboard.addKey("S"),
      left: this.scene.input.keyboard.addKey("A"),
      right: this.scene.input.keyboard.addKey("D"),
    }
  }

  // Função para resetar todas as propriedades aos valores iniciais
  resetToInitialValues() {
    this.health = this.initialHealth
    this.maxHealth = this.initialMaxHealth
    this.arrowDamage = this.initialArrowDamage
    this.movementSpeed = this.initialMovementSpeed
    this.multiArrow = this.initialMultiArrow
    this.arrowCooldown = this.initialArrowCooldown
    this.canMove = true
    this.invincibleTime = 0
    this.lastDamageTime = 0
    this.lastArrowTime = 0
    this.lastCollisionDamageTime = 0 // Reset do cooldown de dano de colisão

    // Reseta a textura do jogador
    this.player.setTexture("player")
    this.player.setAlpha(1)

    // Atualiza UI
    this.updateHealthBar()
    this.updateHealthText()

    console.log("Player resetado aos valores iniciais")
  }

  takeDamage(amount) {
    if (this.scene.time.now - this.invincibleTime > this.invincibleDuration) {
      this.health -= amount
      if (this.health <= 0) {
        this.health = 0
        this.die()
      }
      this.updateHealthBar()
      this.updateHealthText()
      this.invincibleTime = this.scene.time.now
    }
  }

  // Verifica se o player pode causar dano de colisão
  canDealCollisionDamage() {
    return this.scene.time.now - this.lastCollisionDamageTime > this.collisionDamageCooldown
  }

  // Registra que o player causou dano de colisão
  dealCollisionDamage() {
    this.lastCollisionDamageTime = this.scene.time.now
  }

  updateHealthBar() {
    this.healthBar.clear()
    this.healthBar.fillStyle(0x00ff00, 1) // verde
    this.healthBar.fillRect(this.player.x - 25, this.player.y - 55, 50 * (this.health / this.maxHealth), 5)
  }

  updateHealthText() {
    this.healthText.setText(`${this.health}/${this.maxHealth}`)
    this.healthText.setPosition(this.player.x - 15, this.player.y - 50)
  }

  die() {
    console.log("Game Over!")

    // Reseta poderes quando morre
    if (this.scene.powerUpSystem) {
      this.scene.powerUpSystem.resetPowerUps()
    }

    // Para o movimento do jogador
    this.canMove = false

    // Substitui a imagem do jogador pela imagem de morte
    this.player.setTexture("playerDead")

    // Pausa a física do jogo
    if (this.scene.physics) {
      this.scene.physics.pause()
    }

    // Desabilita a atualização do jogador e inimigos
    this.scene.gameOver = true
    this.scene.enemiesActive = false

    // Exibe a tela de Game Over
    const gameOverImage = this.scene.add.image(this.scene.cameras.main.centerX, 200, "gameOverImage").setScale(0.7)
    gameOverImage.setDepth(200)

    // Mostra a opção de "Jogar Novamente"
    const playAgainButton = this.scene.add
      .text(this.scene.cameras.main.centerX, 350, "Jogar Novamente", {
        fontSize: "32px",
        fill: "#fff",
        fontStyle: "bold",
      })
      .setOrigin(0.5)
      .setInteractive()
      .setDepth(201)

    // Adicionando borda ao redor do botão
    playAgainButton.setStroke("#000", 10)
    playAgainButton.setPadding(10)

    // Interação do botão "Jogar Novamente"
    playAgainButton.on("pointerdown", () => {
      console.log("Reiniciando jogo...")
      // Reinicia completamente a cena
      this.scene.scene.restart()
    })

    // Botão "Sair"
    const exitButton = this.scene.add
      .text(this.scene.cameras.main.centerX, 450, "Sair", {
        fontSize: "32px",
        fill: "#fff",
        fontStyle: "bold",
      })
      .setOrigin(0.5)
      .setInteractive()
      .setDepth(201)

    // Adicionando borda ao redor do botão
    exitButton.setStroke("#000", 10)
    exitButton.setPadding(10)

    // Interação do botão "Sair"
    exitButton.on("pointerdown", () => {
      window.close()
    })
  }

  getClosestEnemy() {
    let minDist = Number.POSITIVE_INFINITY
    let closest = null

    this.scene.enemyGroup.forEach((enemy) => {
      if (enemy.health > 0) {
        // Considerar apenas inimigos vivos
        const dist = Phaser.Math.Distance.Between(this.player.x, this.player.y, enemy.enemy.x, enemy.enemy.y)
        if (dist < minDist) {
          minDist = dist
          closest = enemy
        }
      }
    })

    return closest
  }

  isBlocked(x, y) {
    return this.scene.obstaculos?.some((ob) => Phaser.Math.Distance.Between(x, y, ob.x, ob.y) < 40)
  }

  // Função para disparar múltiplas flechas
  shootArrows() {
    const closestEnemy = this.getClosestEnemy()
    if (!closestEnemy) return

    for (let i = 0; i < this.multiArrow; i++) {
      this.scene.time.delayedCall(i * 300, () => {
        // 0.3 segundos entre cada flecha
        const arrow = new Arrow(this.scene, this.player.x, this.player.y, closestEnemy, this.arrowDamage)
        this.scene.arrows.push(arrow)
      })
    }
  }

  update() {
    if (this.scene.gameOver) {
      return // Não faz nada se o jogo acabou
    }

    // Não permite movimento se estiver a selecionar poder
    if (!this.canMove || (this.scene.powerUpSystem && this.scene.powerUpSystem.isSelectingPower)) {
      this.updateHealthBar()
      this.updateHealthText()
      return
    }

    let dx = 0
    let dy = 0
    const speed = this.movementSpeed // Usa a velocidade modificável

    if (this.cursors.left.isDown || this.keys.left.isDown) {
      dx = -speed
    } else if (this.cursors.right.isDown || this.keys.right.isDown) {
      dx = speed
    }

    if (this.cursors.up.isDown || this.keys.up.isDown) {
      dy = -speed
    } else if (this.cursors.down.isDown || this.keys.down.isDown) {
      dy = speed
    }

    // Verificar se o próximo movimento está bloqueado
    const nextX = this.player.x + dx
    const nextY = this.player.y + dy

    if (!this.isBlocked(nextX, this.player.y)) {
      this.player.x = nextX
    }
    if (!this.isBlocked(this.player.x, nextY)) {
      this.player.y = nextY
    }

    const bounds = this.scene.gridBounds

    if (this.player.x - this.hitbox.width / 2 < bounds.left) {
      this.player.x = bounds.left + this.hitbox.width / 2
    } else if (this.player.x + this.hitbox.width / 2 > bounds.right) {
      this.player.x = bounds.right - this.hitbox.width / 2
    }

    if (this.player.y - this.hitbox.height / 2 < bounds.top) {
      this.player.y = bounds.top + this.hitbox.height / 2
    } else if (this.player.y + this.hitbox.height / 2 > bounds.bottom) {
      this.player.y = bounds.bottom - this.hitbox.height / 2
    }

    this.hitbox.setPosition(this.player.x, this.player.y)
    this.updateHealthBar()
    this.updateHealthText()

    // Disparo automático com múltiplas flechas
    const isStopped = dx === 0 && dy === 0
    if (isStopped && this.scene.time.now - this.lastArrowTime > this.arrowCooldown) {
      this.shootArrows() // Usa função de múltiplas flechas
      this.lastArrowTime = this.scene.time.now
    }
  }
}
