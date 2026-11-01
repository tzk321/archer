// src/MagoExplosivo.js

export default class MagoExplosivo {
  constructor(scene, x, y) {
    this.scene = scene

    this.enemy = scene.add.image(x, y, "mago").setScale(0.15)
    this.enemy.setOrigin(0.5, 0.5)

    this.maxHealth = 12500
    this.health = this.maxHealth
    this.speed = 0.5
    this.damage = 350

    this.isInvincible = false
    this.invincibilityDuration = 300
    this.lastDamageTime = 0

    this.moveTimer = 0
    this.moveInterval = 3000
    this.targetPosition = { x: x, y: y }
    this.isMoving = false

    this.attackTimer = 0
    this.attackInterval = 2000
    this.isLowHealth = false
    this.explosionCircles = []

    this.teleportTimer = 0
    this.teleportInterval = 8000
    this.isTeleporting = false

    this.hitbox = scene.add.rectangle(x, y, 60, 60, 0x00ff00, 0)
    this.hitbox.setOrigin(0.5, 0.5)

    this.isEnemy = true
    this.isDead = false

    this.createHealthBar()
  }

  createHealthBar() {
    const barWidth = 100
    const barHeight = 10
    const yOffset = -70

    this.healthBarBg = this.scene.add.rectangle(this.enemy.x, this.enemy.y + yOffset, barWidth, barHeight, 0x000000)
    this.healthBar = this.scene.add.rectangle(this.enemy.x, this.enemy.y + yOffset, barWidth, barHeight, 0x8a2be2)
  }

  updateHealthBar() {
    if (this.healthBar && this.healthBarBg && !this.isDead) {
      const healthPercent = this.health / this.maxHealth
      this.healthBar.scaleX = healthPercent

      this.healthBarBg.setPosition(this.enemy.x, this.enemy.y - 70)
      this.healthBar.setPosition(this.enemy.x, this.enemy.y - 70)

      if (healthPercent <= 0.3 && !this.isLowHealth) {
        this.isLowHealth = true
        this.attackInterval = 1200
        console.log("Mago entrou em modo fúria!")
      }
    }
  }

  takeDamage(dano) {
    if (this.isDead || this.isInvincible) return

    this.isInvincible = true
    this.lastDamageTime = this.scene.time.now

    this.health -= dano
    this.updateHealthBar()

    // Dano
    this.enhancedMageDamageEffect()

    this.scene.time.delayedCall(this.invincibilityDuration, () => {
      this.isInvincible = false
    })

    if (this.health <= 0) {
      this.die()
    }
  }

  // Dano
  enhancedMageDamageEffect() {
    // Cor dano
    this.scene.tweens.add({
      targets: this.enemy,
      tint: 0x9932cc,
      duration: 150,
      yoyo: true,
      onComplete: () => {
        if (!this.isDead) {
          this.enemy.clearTint()
        }
      },
    })

    // Pulsação
    this.scene.tweens.add({
      targets: this.enemy,
      scaleX: this.enemy.scaleX * 1.15,
      scaleY: this.enemy.scaleY * 1.15,
      duration: 100,
      yoyo: true,
      ease: "Power2",
    })

    // Particulas magicas
    this.createMagicDamageParticles()

    // Aura mágica
    this.createMagicAura()
  }

  // Partículas mágicas específicas
  createMagicDamageParticles() {
    for (let i = 0; i < 8; i++) {
      const particle = this.scene.add.circle(
        this.enemy.x + Phaser.Math.Between(-25, 25),
        this.enemy.y + Phaser.Math.Between(-25, 25),
        Phaser.Math.Between(2, 4),
        0x9370db,
      )

      // Movimento em espiral para cima
      const angle = (i / 8) * Math.PI * 2
      const targetX = particle.x + Math.cos(angle) * 20
      const targetY = particle.y - 40 // Sobe

      this.scene.tweens.add({
        targets: particle,
        x: targetX,
        y: targetY,
        alpha: 0,
        scaleX: 0.1,
        scaleY: 0.1,
        duration: 500,
        ease: "Power2.easeOut",
        onComplete: () => particle.destroy(),
      })

      // Rotação da partícula
      this.scene.tweens.add({
        targets: particle,
        rotation: Math.PI * 2,
        duration: 500,
      })
    }
  }

  // Aura mágica temporária
  createMagicAura() {
    const aura = this.scene.add.circle(this.enemy.x, this.enemy.y, 40, 0x8a2be2, 0.3)

    this.scene.tweens.add({
      targets: aura,
      scaleX: 1.5,
      scaleY: 1.5,
      alpha: 0,
      duration: 400,
      ease: "Power2.easeOut",
      onComplete: () => aura.destroy(),
    })
  }

  die(skipCount = false) {
    if (this.isDead) return
    this.isDead = true

    // Efeito morte
    this.createEnhancedMageDeathEffect()

    this.explosionCircles.forEach((circle) => {
      if (circle.graphic) circle.graphic.destroy()
      if (circle.timer) circle.timer.remove()
    })
    this.explosionCircles = []

    if (this.scene.enemyGroup) {
      const index = this.scene.enemyGroup.indexOf(this)
      if (index > -1) {
        this.scene.enemyGroup.splice(index, 1)
      }
    }

    if (!skipCount) {
      this.scene.monstersKilled++
      this.scene.monstersKilledThisPhase++
      this.scene.chefaoMorreu()
    }
  }

  // Efeito morte
  createEnhancedMageDeathEffect() {
    // Explosão final
    const finalExplosion = this.scene.add.circle(this.enemy.x, this.enemy.y, 80, 0x9932cc, 0.6)
    this.scene.tweens.add({
      targets: finalExplosion,
      scaleX: 3,
      scaleY: 3,
      alpha: 0,
      duration: 800,
      ease: "Power2.easeOut",
      onComplete: () => finalExplosion.destroy(),
    })

    // Ondas energia
    for (let wave = 0; wave < 3; wave++) {
      this.scene.time.delayedCall(wave * 150, () => {
        const energyWave = this.scene.add.circle(this.enemy.x, this.enemy.y, 20, 0x8a2be2, 0.4)
        this.scene.tweens.add({
          targets: energyWave,
          scaleX: 4,
          scaleY: 4,
          alpha: 0,
          duration: 600,
          ease: "Power2.easeOut",
          onComplete: () => energyWave.destroy(),
        })
      })
    }

    // Particulas magicas
    for (let i = 0; i < 12; i++) {
      const particle = this.scene.add.circle(this.enemy.x, this.enemy.y, Phaser.Math.Between(4, 8), 0x9370db)

      const angle = (i / 12) * Math.PI * 2
      const distance = Phaser.Math.Between(60, 100)

      this.scene.tweens.add({
        targets: particle,
        x: particle.x + Math.cos(angle) * distance,
        y: particle.y + Math.sin(angle) * distance,
        rotation: Math.PI * 4,
        alpha: 0,
        duration: 1000,
        ease: "Power2.easeOut",
        onComplete: () => particle.destroy(),
      })
    }

    // Mago desaparecer
    this.scene.tweens.add({
      targets: [this.enemy, this.healthBar, this.healthBarBg],
      alpha: 0,
      scaleX: 0,
      scaleY: 0,
      duration: 800,
      delay: 200,
      onComplete: () => {
        this.destroy()
      },
    })
  }


  moveStrategically() {
    if (this.isDead || this.isTeleporting) return

    const now = this.scene.time.now

    if (now - this.moveTimer > this.moveInterval && !this.isMoving) {
      const bounds = this.scene.gridBounds
      const player = this.scene.player.player

      let newX, newY
      do {
        newX = Phaser.Math.Between(bounds.left + 60, bounds.right - 60)
        newY = Phaser.Math.Between(bounds.top + 60, bounds.bottom - 60)
      } while (Phaser.Math.Distance.Between(newX, newY, player.x, player.y) < 150)

      this.targetPosition = { x: newX, y: newY }
      this.isMoving = true
      this.moveTimer = now
    }

    if (this.isMoving) {
      const distance = Phaser.Math.Distance.Between(
        this.enemy.x,
        this.enemy.y,
        this.targetPosition.x,
        this.targetPosition.y,
      )

      if (distance > 5) {
        const angle = Phaser.Math.Angle.Between(
          this.enemy.x,
          this.enemy.y,
          this.targetPosition.x,
          this.targetPosition.y,
        )
        this.enemy.x += Math.cos(angle) * this.speed
        this.enemy.y += Math.sin(angle) * this.speed
        this.hitbox.setPosition(this.enemy.x, this.enemy.y)
      } else {
        this.isMoving = false
      }
    }
  }

  handleTeleport() {
    if (this.isDead) return

    const now = this.scene.time.now

    if (now - this.teleportTimer > this.teleportInterval && !this.isTeleporting) {
      this.startTeleport()
      this.teleportTimer = now
    }
  }

  startTeleport() {
    this.isTeleporting = true

    this.scene.tweens.add({
      targets: this.enemy,
      alpha: 0,
      scale: 0.5,
      duration: 300,
      onComplete: () => {
        const bounds = this.scene.gridBounds
        const newX = Phaser.Math.Between(bounds.left + 60, bounds.right - 60)
        const newY = Phaser.Math.Between(bounds.top + 60, bounds.bottom - 60)

        this.enemy.setPosition(newX, newY)
        this.hitbox.setPosition(newX, newY)

        this.scene.tweens.add({
          targets: this.enemy,
          alpha: 1,
          scale: 0.15,
          duration: 300,
          onComplete: () => {
            this.isTeleporting = false
          },
        })
      },
    })
  }

  handleAttacks() {
    if (this.isDead || this.isTeleporting) return

    const now = this.scene.time.now

    if (now - this.attackTimer > this.attackInterval) {
      if (this.isLowHealth) {
        this.createMultipleExplosionCircles()
      } else {
        this.createExplosionCircle()
      }
      this.attackTimer = now
    }
  }

  createExplosionCircle() {
    const player = this.scene.player.player
    const bounds = this.scene.gridBounds

    let targetX, targetY
    if (Math.random() < 0.7) {
      const offset = 80
      targetX = player.x + Phaser.Math.Between(-offset, offset)
      targetY = player.y + Phaser.Math.Between(-offset, offset)
    } else {
      targetX = Phaser.Math.Between(bounds.left + 40, bounds.right - 40)
      targetY = Phaser.Math.Between(bounds.top + 40, bounds.bottom - 40)
    }

    targetX = Phaser.Math.Clamp(targetX, bounds.left + 40, bounds.right - 40)
    targetY = Phaser.Math.Clamp(targetY, bounds.top + 40, bounds.bottom - 40)

    this.createExplosionAt(targetX, targetY)
  }

  createMultipleExplosionCircles() {
    const numCircles = Phaser.Math.Between(3, 5)
    for (let i = 0; i < numCircles; i++) {
      this.scene.time.delayedCall(i * 200, () => {
        this.createExplosionCircle()
      })
    }
  }

  createExplosionAt(x, y) {
    const radius = 50

    const warningCircle = this.scene.add.circle(x, y, radius, 0xff0000, 0.3)
    warningCircle.setStrokeStyle(3, 0xff0000)

    const explosionData = {
      x: x,
      y: y,
      radius: radius,
      graphic: warningCircle,
      timer: null,
    }

    explosionData.timer = this.scene.time.delayedCall(1000, () => {
      this.explodeCircle(explosionData)
    })

    this.explosionCircles.push(explosionData)
  }

  explodeCircle(explosionData) {
    if (this.isDead) return

    if (explosionData.graphic) {
      explosionData.graphic.destroy()
    }

    const explosionEffect = this.scene.add.circle(explosionData.x, explosionData.y, explosionData.radius, 0xff4500, 0.8)

    this.scene.tweens.add({
      targets: explosionEffect,
      scaleX: 1.5,
      scaleY: 1.5,
      alpha: 0,
      duration: 300,
      onComplete: () => {
        explosionEffect.destroy()
      },
    })

    const player = this.scene.player.player
    const distance = Phaser.Math.Distance.Between(player.x, player.y, explosionData.x, explosionData.y)

    if (distance <= explosionData.radius) {
      this.scene.player.takeDamage(this.damage)
      this.scene.showDamage(player.x, player.y - 40, this.damage, "#ff4444", "player")
    }

    const index = this.explosionCircles.indexOf(explosionData)
    if (index > -1) {
      this.explosionCircles.splice(index, 1)
    }
  }

  update(player) {
    if (this.isDead) return

    this.moveStrategically()
    this.handleTeleport()
    this.handleAttacks()
    this.updateHealthBar()
  }

  destroy() {
    this.explosionCircles.forEach((circle) => {
      if (circle.graphic) circle.graphic.destroy()
      if (circle.timer) circle.timer.remove()
    })

    if (this.enemy) this.enemy.destroy()
    if (this.hitbox) this.hitbox.destroy()
    if (this.healthBar) this.healthBar.destroy()
    if (this.healthBarBg) this.healthBarBg.destroy()
  }
}
