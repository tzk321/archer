// src/PlantShooterEnemy.js

export default class PlantShooterEnemy {
  constructor(scene, x, y, key = "plantEnemy") {
    this.scene = scene
    this.enemy = scene.add.image(x, y, key).setScale(0.08)
    this.hitbox = scene.add.ellipse(x, y, 60, 70, 0x00ff00, 0)
    this.hitbox.setOrigin(0.5, 0.5)

    this.health = 700
    this.maxHealth = 700
    this.healthBar = scene.add.graphics()
    this.updateHealthBar()

    this.damage = 25
    this.lastDamageTime = 0
    this.invincibleDuration = 200

    this.lastShotTime = 0
    this.shootInterval = 2000

    this.projectiles = []
    this.alive = true
    this.isDying = false
  }

  takeDamage(amount) {
    const now = this.scene.time.now
    if (!this.alive || this.isDying) return
    if (now - this.lastDamageTime > this.invincibleDuration) {
      this.health -= amount
      this.lastDamageTime = now

      if (this.health <= 0) this.die()
      else this.flashEnhanced()

      this.updateHealthBar()
    }
  }

  flashEnhanced() {
    const originalX = this.enemy.x
    const originalY = this.enemy.y
    const originalScale = this.enemy.scaleX

    this.enemy.setTint(0xffff44)

    this.scene.tweens.add({
      targets: this.enemy,
      rotation: 0.2,
      scaleY: originalScale * 0.95,
      duration: 150,
      yoyo: true,
      ease: "Power2",
    })

    this.scene.tweens.add({
      targets: this.enemy,
      x: originalX + Math.sin(this.scene.time.now * 0.1) * 2,
      duration: 100,
      yoyo: true,
      repeat: 2,
      onComplete: () => {
        this.enemy.setPosition(originalX, originalY)
      },
    })

    this.createFallingLeaves()

    this.scene.time.delayedCall(this.invincibleDuration, () => {
      if (this.enemy) {
        this.enemy.clearTint()
        this.enemy.setRotation(0)
      }
    })
  }

  createFallingLeaves() {
    for (let i = 0; i < 3; i++) {
      const leaf = this.scene.add.ellipse(
        this.enemy.x + Phaser.Math.Between(-15, 15),
        this.enemy.y + Phaser.Math.Between(-10, 5),
        6,
        4,
        0x228b22,
      )

      this.scene.tweens.add({
        targets: leaf,
        x: leaf.x + Phaser.Math.Between(-20, 20),
        y: leaf.y + 30,
        rotation: Math.PI * 2,
        alpha: 0,
        duration: 600,
        ease: "Power2.easeOut",
        onComplete: () => leaf.destroy(),
      })
    }
  }

  updateHealthBar() {
    this.healthBar.clear()
    if (this.health < this.maxHealth) {
      this.healthBar.fillStyle(0xff0000, 1)
      this.healthBar.fillRect(this.enemy.x - 30, this.enemy.y - 55, 60 * (this.health / this.maxHealth), 5)
    }
  }

  die(skipCount = false) {
    this.alive = false
    this.isDying = true

    this.projectiles.forEach((proj) => {
      if (proj && proj.destroy) {
        proj.destroy()
      }
    })
    this.projectiles = []

    this.createPlantDecomposition()

    if (!skipCount) {
      this.scene.monstersKilled++
      this.scene.monstersKilledThisPhase++
    }
  }

  createPlantDecomposition() {
    this.scene.tweens.add({
      targets: this.enemy,
      scaleX: this.enemy.scaleX * 0.3,
      scaleY: this.enemy.scaleY * 0.1,
      rotation: 0.5,
      alpha: 0.7,
      duration: 800,
      ease: "Power2.easeIn",
      onComplete: () => {
        this.createSoilEffect()
        this.enemy.destroy()
        this.hitbox.destroy()
        this.healthBar.destroy()
      },
    })

    for (let i = 0; i < 8; i++) {
      this.scene.time.delayedCall(i * 100, () => {
        const leaf = this.scene.add.ellipse(
          this.enemy.x + Phaser.Math.Between(-20, 20),
          this.enemy.y + Phaser.Math.Between(-15, 5),
          Phaser.Math.Between(4, 8),
          Phaser.Math.Between(3, 6),
          Phaser.Math.Between(0x228b22, 0x32cd32),
        )

        this.scene.tweens.add({
          targets: leaf,
          x: leaf.x + Phaser.Math.Between(-40, 40),
          y: leaf.y + Phaser.Math.Between(40, 80),
          rotation: Math.PI * Phaser.Math.Between(1, 3),
          alpha: 0,
          duration: 1000,
          ease: "Power2.easeOut",
          onComplete: () => leaf.destroy(),
        })
      })
    }

    for (let i = 0; i < 4; i++) {
      const seed = this.scene.add.circle(this.enemy.x, this.enemy.y, 2, 0x8b4513)

      const angle = (i / 4) * Math.PI * 2
      const distance = Phaser.Math.Between(30, 60)

      this.scene.tweens.add({
        targets: seed,
        x: seed.x + Math.cos(angle) * distance,
        y: seed.y + Math.sin(angle) * distance,
        alpha: 0,
        duration: 1200,
        ease: "Power2.easeOut",
        onComplete: () => seed.destroy(),
      })
    }
  }

  createSoilEffect() {
    const soil = this.scene.add.ellipse(this.enemy.x, this.enemy.y + 10, 25, 15, 0x8b4513, 0.6)

    this.scene.tweens.add({
      targets: soil,
      alpha: 0,
      duration: 2000,
      onComplete: () => soil.destroy(),
    })
  }

  update(player) {
    if (!this.alive || this.isDying) {
      if (this.isDying && this.projectiles.length > 0) {
        this.projectiles.forEach((proj) => {
          if (proj && proj.destroy) {
            proj.destroy()
          }
        })
        this.projectiles = []
      }
      return
    }

    const now = this.scene.time.now

    if (now - this.lastShotTime > this.shootInterval) {
      this.shootProjectile(player)
      this.lastShotTime = now
    }

    const bounds = this.scene.gridBounds

    this.projectiles.forEach((proj, index) => {
      proj.x += proj.vx
      proj.y += proj.vy

      if (proj.x < bounds.left || proj.x > bounds.right || proj.y < bounds.top || proj.y > bounds.bottom) {
        proj.destroy()
        this.projectiles.splice(index, 1)
        return
      }

      if (this.scene.obstaculos?.some((ob) => Phaser.Math.Distance.Between(proj.x, proj.y, ob.x, ob.y) < 30)) {
        proj.destroy()
        this.projectiles.splice(index, 1)
        return
      }

      if (Phaser.Math.Distance.Between(proj.x, proj.y, player.x, player.y) < 30) {
        this.scene.player.takeDamage(this.damage)
        this.scene.showDamage(player.x, player.y - 30, this.damage, "#ff0000", "proj_" + Math.random())
        proj.destroy()
        this.projectiles.splice(index, 1)
      }
    })

    this.hitbox.setPosition(this.enemy.x, this.enemy.y)
    this.updateHealthBar()
  }

  shootProjectile(player) {
    if (!this.alive || this.isDying) return

    const proj = this.scene.add.circle(this.enemy.x, this.enemy.y, 6, 0x006400)
    const dx = player.x - this.enemy.x
    const dy = player.y - this.enemy.y
    const len = Math.hypot(dx, dy)
    const speed = 2
    proj.vx = (dx / len) * speed
    proj.vy = (dy / len) * speed
    this.projectiles.push(proj)
  }
}