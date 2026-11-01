// src/ChefaoDividido.js

export default class ChefaoDividido {
  constructor(scene, x, y, tipo = "grande") {
    this.scene = scene

    this.enemy = scene.add.image(x, y, "chefao").setScale(tipo === "grande" ? 0.2 : tipo === "medio" ? 0.1 : 0.05)
    this.enemy.setOrigin(0.5, 0.5)

    this.tipo = tipo
    this.maxHealth = tipo === "grande" ? 2500 : tipo === "medio" ? 1250 : 750
    this.health = this.maxHealth
    this.speed = tipo === "grande" ? 1 : tipo === "medio" ? 1.5 : 2
    this.damage = 150

    this.isInvincible = false
    this.invincibilityDuration = 300
    this.lastDamageTime = 0

    this.changeDirectionInterval = 2000
    this.lastDirectionChange = 0
    this.direction = new Phaser.Math.Vector2(Phaser.Math.Between(-1, 1), Phaser.Math.Between(-1, 1)).normalize()

    const hitboxSize = tipo === "grande" ? 80 : tipo === "medio" ? 60 : 40
    this.hitbox = scene.add.rectangle(x, y, hitboxSize, hitboxSize, 0x00ff00, 0)
    this.hitbox.setOrigin(0.5, 0.5)

    this.isEnemy = true
    this.isDead = false

    this.createHealthBar()
  }

  createHealthBar() {
    const barWidth = this.tipo === "grande" ? 80 : this.tipo === "medio" ? 60 : 40
    const barHeight = 8
    const yOffset = this.tipo === "grande" ? -60 : this.tipo === "medio" ? -45 : -30

    this.healthBarBg = this.scene.add.rectangle(this.enemy.x, this.enemy.y + yOffset, barWidth, barHeight, 0x000000)
    this.healthBar = this.scene.add.rectangle(this.enemy.x, this.enemy.y + yOffset, barWidth, barHeight, 0xff0000)
  }

  updateHealthBar() {
    if (this.healthBar && this.healthBarBg && !this.isDead) {
      const healthPercent = this.health / this.maxHealth
      this.healthBar.scaleX = healthPercent

      const yOffset = this.tipo === "grande" ? -60 : this.tipo === "medio" ? -45 : -30
      this.healthBarBg.setPosition(this.enemy.x, this.enemy.y + yOffset)
      this.healthBar.setPosition(this.enemy.x, this.enemy.y + yOffset)
    }
  }

  takeDamage(dano) {
    this.receberDano(dano)
  }

  receberDano(dano) {
    if (this.isDead || this.isInvincible) return

    this.isInvincible = true
    this.lastDamageTime = this.scene.time.now

    this.health -= dano
    this.updateHealthBar()

    // Efeito dano
    this.startEnhancedInvincibilityEffect()

    this.scene.time.delayedCall(this.invincibilityDuration, () => {
      this.isInvincible = false
      if (!this.isDead) {
        this.enemy.setAlpha(1)
        this.enemy.clearTint()
      }
    })

    if (this.health <= 0) {
      this.die()
    }
  }

  // Efeito dano
  startEnhancedInvincibilityEffect() {
    if (this.isDead) return

    // Piscar quando dano
    this.scene.tweens.add({
      targets: this.enemy,
      alpha: 0.2,
      duration: 80,
      yoyo: true,
      repeat: Math.floor(this.invincibilityDuration / 160),
      onComplete: () => {
        if (!this.isDead) {
          this.enemy.setAlpha(1)
        }
      },
    })

    // Pulsação e vermelho
    this.scene.tweens.add({
      targets: this.enemy,
      tint: 0xff0000,
      scaleX: this.enemy.scaleX * 1.1,
      scaleY: this.enemy.scaleY * 1.1,
      duration: 100,
      yoyo: true,
      repeat: 1,
      onComplete: () => {
        if (!this.isDead && !this.isInvincible) {
          this.enemy.clearTint()
        }
      },
    })

    // Partículas de aranha ferida
    this.createSpiderDamageParticles()

    // Tremer
    const originalX = this.enemy.x
    const originalY = this.enemy.y
    this.scene.tweens.add({
      targets: this.enemy,
      x: originalX + Phaser.Math.Between(-3, 3),
      y: originalY + Phaser.Math.Between(-3, 3),
      duration: 50,
      yoyo: true,
      repeat: 2,
      onComplete: () => {
        this.enemy.setPosition(originalX, originalY)
      },
    })
  }

  // Partículas específicas para aranha
  createSpiderDamageParticles() {
    const particleCount = this.tipo === "grande" ? 6 : this.tipo === "medio" ? 4 : 3

    for (let i = 0; i < particleCount; i++) {
      const particle = this.scene.add.circle(
        this.enemy.x + Phaser.Math.Between(-20, 20),
        this.enemy.y + Phaser.Math.Between(-20, 20),
        Phaser.Math.Between(2, 4),
        0x8b0000,
      )

      const angle = Phaser.Math.Between(0, 360)
      const distance = Phaser.Math.Between(15, 30)
      const targetX = particle.x + Math.cos(angle) * distance
      const targetY = particle.y + Math.sin(angle) * distance

      this.scene.tweens.add({
        targets: particle,
        x: targetX,
        y: targetY,
        alpha: 0,
        scaleX: 0.1,
        scaleY: 0.1,
        duration: 400,
        ease: "Power2.easeOut",
        onComplete: () => particle.destroy(),
      })
    }
  }

  die(skipCount = false) {
    this.morrer(skipCount)
  }

  morrer(skipCount = false) {
    if (this.isDead) return
    this.isDead = true

    this.isInvincible = false

    if (this.scene.enemyGroup) {
      const index = this.scene.enemyGroup.indexOf(this)
      if (index > -1) {
        this.scene.enemyGroup.splice(index, 1)
      }
    }

    if (!skipCount) {
      this.scene.monstersKilled++
      this.scene.monstersKilledThisPhase++
    }

    // Divisão efeito
    if (this.tipo === "grande") {
      this.enhancedDivisionEffect(() => {
        this.criarChefoesMenores(2, "medio")
      })
    } else if (this.tipo === "medio") {
      this.enhancedDivisionEffect(() => {
        this.criarChefoesMenores(2, "pequeno")
      })
    } else {
      // Aranha pequena - efeito de morte normal
      this.createSpiderDeathEffect()
    }

    this.checkAllBossesDefeated()
  }

  // Efeito divisão
  enhancedDivisionEffect(callback) {
    // Diminuir
    this.scene.tweens.add({
      targets: this.enemy,
      scaleX: 0.05,
      scaleY: 0.05,
      alpha: 0.7,
      duration: 400,
      ease: "Power2.easeIn",
      onComplete: () => {
        // Flash branco no momento da divisão
        const flash = this.scene.add.circle(this.enemy.x, this.enemy.y, 60, 0xffffff, 0.8)
        this.scene.tweens.add({
          targets: flash,
          scaleX: 2,
          scaleY: 2,
          alpha: 0,
          duration: 300,
          onComplete: () => {
            flash.destroy()
            callback() // Cria as aranhas menores
            this.destroy()
          },
        })

        // Partículas de divisão
        this.createDivisionParticles()
      },
    })
  }

  // Partículas no momento da divisão
  createDivisionParticles() {
    for (let i = 0; i < 8; i++) {
      const particle = this.scene.add.circle(this.enemy.x, this.enemy.y, 3, 0xff4500)

      const angle = (i / 8) * Math.PI * 2
      const distance = 40

      this.scene.tweens.add({
        targets: particle,
        x: particle.x + Math.cos(angle) * distance,
        y: particle.y + Math.sin(angle) * distance,
        alpha: 0,
        duration: 500,
        ease: "Power2.easeOut",
        onComplete: () => particle.destroy(),
      })
    }
  }

  // Efeito de morte para aranha pequena
  createSpiderDeathEffect() {
    this.scene.tweens.add({
      targets: [this.enemy, this.healthBar, this.healthBarBg],
      alpha: 0,
      scaleX: 0,
      scaleY: 0,
      duration: 300,
      onComplete: () => {
        this.destroy()
      },
    })

    // Explosão de partículas vermelhas
    for (let i = 0; i < 6; i++) {
      const particle = this.scene.add.circle(this.enemy.x, this.enemy.y, 4, 0x8b0000)

      const angle = (i / 6) * Math.PI * 2
      const distance = 35

      this.scene.tweens.add({
        targets: particle,
        x: particle.x + Math.cos(angle) * distance,
        y: particle.y + Math.sin(angle) * distance,
        alpha: 0,
        duration: 400,
        ease: "Power2.easeOut",
        onComplete: () => particle.destroy(),
      })
    }
  }

  criarChefoesMenores(quantidade, tipoNovo) {
    for (let i = 0; i < quantidade; i++) {
      const offsetX = Phaser.Math.Between(-100, 100)
      const offsetY = Phaser.Math.Between(-100, 100)

      let newX = this.enemy.x + offsetX
      let newY = this.enemy.y + offsetY

      const bounds = this.scene.gridBounds
      newX = Phaser.Math.Clamp(newX, bounds.left + 50, bounds.right - 50)
      newY = Phaser.Math.Clamp(newY, bounds.top + 50, bounds.bottom - 50)

      const novoChefao = new ChefaoDividido(this.scene, newX, newY, tipoNovo)
      this.scene.enemyGroup.push(novoChefao)
    }
  }

  checkAllBossesDefeated() {
    this.scene.time.delayedCall(100, () => {
      const chefoesVivos = this.scene.enemyGroup.filter((enemy) => enemy instanceof ChefaoDividido && !enemy.isDead)

      if (chefoesVivos.length === 0) {
        this.scene.chefaoMorreu()
      }
    })
  }

  moveRandomly() {
    if (this.isDead) return

    const now = this.scene.time.now

    if (now - this.lastDirectionChange > this.changeDirectionInterval) {
      this.direction = new Phaser.Math.Vector2(Phaser.Math.Between(-1, 1), Phaser.Math.Between(-1, 1)).normalize()
      this.lastDirectionChange = now
    }

    const newX = this.enemy.x + this.direction.x * this.speed
    const newY = this.enemy.y + this.direction.y * this.speed

    const bounds = this.scene.gridBounds
    if (newX < bounds.left + 40 || newX > bounds.right - 40) {
      this.direction.x = -this.direction.x
    }
    if (newY < bounds.top + 40 || newY > bounds.bottom - 40) {
      this.direction.y = -this.direction.y
    }

    this.enemy.setPosition(this.enemy.x + this.direction.x * this.speed, this.enemy.y + this.direction.y * this.speed)
    this.hitbox.setPosition(this.enemy.x, this.enemy.y)

    this.updateHealthBar()
  }

  update(player) {
    this.moveRandomly()
  }

  destroy() {
    if (this.enemy) this.enemy.destroy()
    if (this.hitbox) this.hitbox.destroy()
    if (this.healthBar) this.healthBar.destroy()
    if (this.healthBarBg) this.healthBarBg.destroy()
  }
}
