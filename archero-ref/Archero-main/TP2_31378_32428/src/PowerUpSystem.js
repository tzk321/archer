export default class PowerUpSystem {
  constructor(scene) {
    this.scene = scene
    this.powerUps = [
      {
        id: "damage",
        name: "Mais Dano",
        description: "+25 de dano nas flechas",
        icon: "swordIcon",
        effect: () => {
          this.scene.player.arrowDamage = (this.scene.player.arrowDamage || 200) + 25
        },
      },
      {
        id: "damage_plus",
        name: "Dano Supremo",
        description: "+50 de dano nas flechas",
        icon: "swordIcon",
        effect: () => {
          this.scene.player.arrowDamage = (this.scene.player.arrowDamage || 200) + 50
        },
      },
      {
        id: "attack_speed",
        name: "Velocidade de Ataque",
        description: "Ataque 15% mais rápido",
        icon: "arrow",
        effect: () => {
          this.scene.player.arrowCooldown = Math.max(150, this.scene.player.arrowCooldown * 0.7)
        },
      },
      {
        id: "movement_speed",
        name: "Velocidade de Movimento",
        description: "Movimento 10% mais rápido",
        icon: "player",
        effect: () => {
          this.scene.player.movementSpeed = (this.scene.player.movementSpeed || 3) * 1.1
        },
      },
      {
        id: "multi_arrow",
        name: "Multi-Flecha",
        description: "Dispara 2 flechas seguidas",
        icon: "arrow",
        effect: () => {
          this.scene.player.multiArrow = (this.scene.player.multiArrow || 1) + 1
        },
      },
      {
        id: "heal",
        name: "Recuperar Vida",
        description: "+250 de vida",
        icon: "crossIcon",
        effect: () => {
          this.scene.player.health = Math.min(this.scene.player.maxHealth, this.scene.player.health + 250)
          this.scene.player.updateHealthBar()
          this.scene.player.updateHealthText()
        },
      },
      {
        id: "max_health",
        name: "Vida Máxima",
        description: "+200 vida máxima e +100 vida atual",
        icon: "crossIcon",
        effect: () => {
          this.scene.player.maxHealth += 200
          this.scene.player.health = Math.min(this.scene.player.maxHealth, this.scene.player.health + 100)
          this.scene.player.updateHealthBar()
          this.scene.player.updateHealthText()
        },
      },
    ]

    this.activePowerUps = []
    this.isSelectingPower = false
  }

  getRandomPowerUps(count = 3) {
    const shuffled = [...this.powerUps].sort(() => 0.5 - Math.random())
    return shuffled.slice(0, count)
  }

  showPowerUpSelection() {
    // Evita mostrar múltiplas vezes
    if (this.isSelectingPower) {
      return
    }

    // Marca que está selecionando poder
    this.isSelectingPower = true

    // Pausa completamente o jogo
    this.scene.enemiesActive = false
    this.scene.physics?.pause()

    // Para o movimento do jogador
    this.scene.player.canMove = false

    // Fundo escuro semi-transparente
    const overlay = this.scene.add.rectangle(
      this.scene.cameras.main.centerX,
      this.scene.cameras.main.centerY,
      this.scene.cameras.main.width,
      this.scene.cameras.main.height,
      0x000000,
      0.8,
    )
    overlay.setDepth(100)

    // Título
    const title = this.scene.add
      .text(this.scene.cameras.main.centerX, 150, "Escolha um Poder", {
        fontSize: "32px",
        fill: "#ffffff",
        fontStyle: "bold",
        stroke: "#000000",
        strokeThickness: 4,
      })
      .setOrigin(0.5)
      .setDepth(101)

    // Pega 3 poderes aleatórios
    const selectedPowerUps = this.getRandomPowerUps(3)
    const powerUpElements = []

    selectedPowerUps.forEach((powerUp, index) => {
      const x = this.scene.cameras.main.centerX + (index - 1) * 250
      const y = this.scene.cameras.main.centerY

      // Fundo do botão
      const buttonBg = this.scene.add
        .rectangle(x, y, 200, 250, 0x4a4a4a, 0.9)
        .setStrokeStyle(3, 0xffffff)
        .setInteractive()
        .setDepth(101)

      // Ícone do poder - escala menor e fixa
      const iconScale = powerUp.icon === "player" ? 0.08 : 0.12
      const icon = this.scene.add
        .image(x, y - 60, powerUp.icon)
        .setScale(iconScale)
        .setDepth(102)

      // Nome do poder
      const nameText = this.scene.add
        .text(x, y - 10, powerUp.name, {
          fontSize: "18px",
          fill: "#ffffff",
          fontStyle: "bold",
          align: "center",
        })
        .setOrigin(0.5)
        .setDepth(102)

      // Descrição do poder
      const descText = this.scene.add
        .text(x, y + 30, powerUp.description, {
          fontSize: "14px",
          fill: "#cccccc",
          align: "center",
          wordWrap: { width: 180 },
        })
        .setOrigin(0.5)
        .setDepth(102)

      // Efeito hover - apenas no fundo, não nos elementos internos
      buttonBg.on("pointerover", () => {
        buttonBg.setStrokeStyle(4, 0x00ff00)
        // Efeito sutil apenas no fundo
        this.scene.tweens.add({
          targets: buttonBg,
          scaleX: 1.02,
          scaleY: 1.02,
          duration: 150,
          ease: "Power2",
        })
      })

      buttonBg.on("pointerout", () => {
        buttonBg.setStrokeStyle(3, 0xffffff)
        // Volta ao normal
        this.scene.tweens.add({
          targets: buttonBg,
          scaleX: 1,
          scaleY: 1,
          duration: 150,
          ease: "Power2",
        })
      })

      // Clique no botão
      buttonBg.on("pointerdown", () => {
        this.selectPowerUp(powerUp, [overlay, title, ...powerUpElements.flat()])
      })

      powerUpElements.push([buttonBg, icon, nameText, descText])
    })
  }

  selectPowerUp(powerUp, elementsToDestroy) {
    // Aplica o efeito do poder
    powerUp.effect()

    // Adiciona à lista de poderes ativos
    this.activePowerUps.push(powerUp)

    console.log(`Poder selecionado: ${powerUp.name}`)
    console.log(`Poderes ativos: ${this.activePowerUps.length}`)

    // Efeito visual de seleção
    const selectedText = this.scene.add
      .text(this.scene.cameras.main.centerX, this.scene.cameras.main.centerY - 100, `${powerUp.name} Ativado!`, {
        fontSize: "24px",
        fill: "#00ff00",
        fontStyle: "bold",
        stroke: "#000000",
        strokeThickness: 3,
      })
      .setOrigin(0.5)
      .setDepth(103)

    // Remove elementos da tela após delay
    this.scene.time.delayedCall(1000, () => {
      elementsToDestroy.forEach((element) => {
        if (element && element.destroy) {
          element.destroy()
        }
      })
      selectedText.destroy()

      // Retoma o jogo e mostra a porta
      this.resumeGame()
    })
  }

  resumeGame() {
    // Marca que não está mais selecionando
    this.isSelectingPower = false

    // Permite movimento do jogador novamente
    this.scene.player.canMove = true

    // Retoma a física
    this.scene.physics?.resume()

    // Não chama continuePhase aqui, apenas permite que a porta apareça
  }

  // Reseta poderes quando o jogador morre
  resetPowerUps() {
    this.activePowerUps = []
    this.isSelectingPower = false
  }
}
