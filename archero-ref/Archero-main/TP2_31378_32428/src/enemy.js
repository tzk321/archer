// src/enemy.js

export default class Enemy {
  constructor(scene, x, y, key) {
    this.scene = scene
    this.enemy = scene.add.image(x, y, key).setScale(0.15)
    this.lastDamageTime = 0
    this.invincibleDuration = 200
    this.showHealthBar = false
    this.speed = 0.8

    this.hitbox = scene.add.ellipse(x, y, 60, 70, 0x808080, 0)
    this.hitbox.setOrigin(0.5, 0.5)

    this.health = 700
    this.maxHealth = 700

    this.healthBar = scene.add.graphics()
    this.updateHealthBar()

    this.damage = 0
    this.isDying = false   // evitar movimento durante morte
  }

  takeDamage(amount) {
    const now = this.scene.time.now

    if (now - this.lastDamageTime > this.invincibleDuration && !this.isDying) {
      this.health -= amount
      this.showHealthBar = true
      this.lastDamageTime = now

      if (this.health <= 0) {
        this.die()
      } else {
        this.flashEnhanced()
      }

      this.updateHealthBar()
    }
  }

  flashEnhanced() {
    const originalX = this.enemy.x
    const originalY = this.enemy.y
    const originalScale = this.enemy.scaleX

    this.enemy.setTint(0xaa88ff) 

    this.scene.tweens.add({
      targets: this.enemy,
      scaleX: originalScale * 1.08,
      scaleY: originalScale * 1.08,
      duration: 120,
      yoyo: true,
      ease: "Power2",
    })

    this.scene.tweens.add({
      targets: this.enemy,
      x: originalX + Phaser.Math.Between(-2, 2),
      y: originalY + Phaser.Math.Between(-2, 2),
      duration: 60,
      yoyo: true,
      repeat: 2,
      onComplete: () => {
        this.enemy.setPosition(originalX, originalY)
      },
    })

    // particulas
    this.createDarkEnergyParticles()

    // Aura demoniaca
    this.createDemonicAura()

    this.scene.time.delayedCall(this.invincibleDuration, () => {
      if (this.enemy) {
        this.enemy.clearTint()
      }
    })
  }

  createDarkEnergyParticles() {
    // partículas
    for (let i = 0; i < 4; i++) {
      const particle = this.scene.add.circle(
        this.enemy.x + Phaser.Math.Between(-10, 10),
        this.enemy.y + Phaser.Math.Between(-10, 10),
        Phaser.Math.Between(1, 3),
        0x6a5acd,
      )

      const angle = Phaser.Math.Between(0, 360)
      const distance = Phaser.Math.Between(15, 25)
      const targetX = particle.x + Math.cos(angle) * distance
      const targetY = particle.y + Math.sin(angle) * distance

      this.scene.tweens.add({
        targets: particle,
        x: targetX,
        y: targetY,
        alpha: 0,
        scaleX: 0.1,
        scaleY: 0.1,
        duration: 300,
        ease: "Power2.easeOut",
        onComplete: () => particle.destroy(),
      })
    }
  }

  createDemonicAura() {
    // Circulo aura
    const aura = this.scene.add.circle(this.enemy.x, this.enemy.y, 20, 0x9370db, 0.2)

    this.scene.tweens.add({
      targets: aura,
      scaleX: 1.3,
      scaleY: 1.3,
      alpha: 0,
      duration: 250,
      ease: "Power2.easeOut",
      onComplete: () => aura.destroy(),
    })
  }

  updateHealthBar() {
    this.healthBar.clear()

    if (this.showHealthBar) {
      this.healthBar.fillStyle(0xff0000, 1)
      this.healthBar.fillRect(this.enemy.x - 30, this.enemy.y - 55, 60 * (this.health / this.maxHealth), 5)
    }
  }

  die(skipCount = false) {
    console.log("Enemy Dead!")
    this.isDying = true

    this.createDemonicBanishment()

    if (!skipCount) {
      this.scene.monstersKilled += 1
      this.scene.monstersKilledThisPhase += 1
    }
  }

  createDemonicBanishment() {
    // Portal menor
    const portal = this.scene.add.circle(this.enemy.x, this.enemy.y + 20, 5, 0x4b0082, 0.6) // Menos opaco

    this.scene.tweens.add({
      targets: portal,
      scaleX: 2, // Reduzido de 3 para 2
      scaleY: 0.4, // Reduzido de 0.5 para 0.4
      alpha: 0.3,
      duration: 500, // Mais rápido
      ease: "Power2.easeOut",
      onComplete: () => portal.destroy(),
    })

    this.scene.tweens.add({
      targets: this.enemy,
      y: this.enemy.y + 25,
      scaleX: this.enemy.scaleX * 0.3,
      scaleY: this.enemy.scaleY * 0.1,
      alpha: 0,
      rotation: 0.3, // Menos rotação
      duration: 600, // Mais rápido
      ease: "Power2.easeIn",
      onComplete: () => {
        this.enemy.destroy()
        this.hitbox.destroy()
        this.healthBar.destroy()
      },
    })

    // energia sombria
    for (let i = 0; i < 5; i++) {
      this.scene.time.delayedCall(i * 80, () => {
        const energy = this.scene.add.circle(
          this.enemy.x + Phaser.Math.Between(-20, 20),
          this.enemy.y + Phaser.Math.Between(-15, 5),
          Phaser.Math.Between(2, 4),
          0x8a2be2,
        )

        this.scene.tweens.add({
          targets: energy,
          x: this.enemy.x,
          y: this.enemy.y + 20,
          scaleX: 0.1,
          scaleY: 0.1,
          alpha: 0,
          duration: 400,
          ease: "Power2.easeIn",
          onComplete: () => energy.destroy(),
        })
      })
    }

    // Onda som
    const soundWave = this.scene.add.circle(this.enemy.x, this.enemy.y, 15, 0x9932cc, 0.15)
    this.scene.tweens.add({
      targets: soundWave,
      scaleX: 2.5,
      scaleY: 2.5,
      alpha: 0,
      duration: 800,
      ease: "Power2.easeOut",
      onComplete: () => soundWave.destroy(),
    })
  }

  handleCollision(playerHitbox) {
    playerHitbox.takeDamage(this.damage)
  }

  canMoveTo(x, y) {
    return !this.scene.obstaculos?.some((ob) => Phaser.Math.Distance.Between(x, y, ob.x, ob.y) < 30)
  }

  update(player) {
    if (this.isDying) return

    const dx = player.x - this.enemy.x
    const dy = player.y - this.enemy.y
    const dist = Math.hypot(dx, dy)

    if (dist > 1) {
      const velocityX = (dx / dist) * this.speed
      const velocityY = (dy / dist) * this.speed

      const newX = this.enemy.x + velocityX
      const newY = this.enemy.y + velocityY

      if (this.canMoveTo(newX, newY)) {
        this.enemy.x = newX
        this.enemy.y = newY
      }
    }

    const bounds = this.scene.gridBounds

    if (this.enemy.x - this.hitbox.width / 2 < bounds.left) {
      this.enemy.x = bounds.left + this.hitbox.width / 2
    } else if (this.enemy.x + this.hitbox.width / 2 > bounds.right) {
      this.enemy.x = bounds.right - this.hitbox.width / 2
    }

    if (this.enemy.y - this.hitbox.height / 2 < bounds.top) {
      this.enemy.y = bounds.top + this.hitbox.height / 2
    } else if (this.enemy.y + this.hitbox.height / 2 > bounds.bottom) {
      this.enemy.y = bounds.bottom - this.hitbox.height / 2
    }

    this.hitbox.setPosition(this.enemy.x, this.enemy.y)
    this.updateHealthBar()
  }
}
