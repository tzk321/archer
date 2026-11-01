// src/TornadoShooterEnemy.js

export default class TornadoShooterEnemy {
  constructor(scene, x, y, key = "tornadoEnemy") {
    this.scene = scene
    this.enemy = scene.add.image(x, y, key).setScale(0.1)
    this.hitbox = scene.add.ellipse(x, y, 60, 70, 0x8888ff, 0).setOrigin(0.5, 0.5)

    this.health = 600
    this.maxHealth = 600
    this.healthBar = scene.add.graphics()
    this.updateHealthBar()

    this.damage = 30
    this.lastDamageTime = 0
    this.invincibleDuration = 300

    this.shootInterval = 3500
    this.lastShotTime = 0

    this.tornadoes = []
    this.tornadoSpeed = 1.2

    this.moving = true
    this.moveDuration = 1000
    this.pauseDuration = 2000
    this.lastMoveToggle = scene.time.now

    this.moveDirection = new Phaser.Math.Vector2(
      Phaser.Math.FloatBetween(-1, 1),
      Phaser.Math.FloatBetween(-1, 1),
    ).normalize()
    this.speed = 1.3

    this.alive = true
  }

  takeDamage(amount) {
    const now = this.scene.time.now
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

    // Ferido
    this.enemy.setTint(0xadd8e6)

    // Tremer
    this.scene.tweens.add({
      targets: this.enemy,
      x: originalX + Math.cos(this.scene.time.now * 0.02) * 3,
      y: originalY + Math.sin(this.scene.time.now * 0.02) * 3,
      duration: 50,
      yoyo: true,
      repeat: 4,
      onComplete: () => {
        this.enemy.setPosition(originalX, originalY)
      },
    })

    const currentRotation = this.enemy.rotation
    this.scene.tweens.add({
      targets: this.enemy,
      rotation: currentRotation + 0.3, // Rotação
      duration: 100,
      yoyo: true, // Volta à posição original
      ease: "Power2",
    })

    // Pulsação
    this.scene.tweens.add({
      targets: this.enemy,
      scaleX: originalScale * 1.15,
      scaleY: originalScale * 1.15,
      duration: 80,
      yoyo: true,
      ease: "Power2",
    })

    // Particulas
    this.createWindParticles()

    // Remove efeitos após invencibilidade
    this.scene.time.delayedCall(this.invincibleDuration, () => {
      if (this.enemy) {
        this.enemy.clearTint()
      }
    })
  }

  // Partículas específicas para vento
  createWindParticles() {
    for (let i = 0; i < 6; i++) {
      const particle = this.scene.add.circle(
        this.enemy.x,
        this.enemy.y,
        Phaser.Math.Between(1, 3),
        0x87ceeb,
      )

      // Movimento em espiral
      const angle = (i / 6) * Math.PI * 2
      const radius = 20

      this.scene.tweens.add({
        targets: particle,
        x: this.enemy.x + Math.cos(angle) * radius,
        y: this.enemy.y + Math.sin(angle) * radius,
        alpha: 0,
        duration: 300,
        ease: "Power2.easeOut",
        onComplete: () => particle.destroy(),
      })

      // Rotação da partícula
      this.scene.tweens.add({
        targets: particle,
        rotation: Math.PI,
        duration: 300,
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

    // Efeito de morte do tornado 
    this.createTornadoDeathEffect()

    this.enemy.destroy()
    this.hitbox.destroy()
    this.healthBar.destroy()
    this.tornadoes.forEach((t) => t.sprite.destroy())

    if (!skipCount) {
      this.scene.monstersKilled++
      this.scene.monstersKilledThisPhase++
    }
  }

  createTornadoDeathEffect() {
    // Explosão em espiral 
    for (let i = 0; i < 8; i++) {
      const particle = this.scene.add.circle(this.enemy.x, this.enemy.y, Phaser.Math.Between(2, 4), 0x4682b4)

      const angle = (i / 8) * Math.PI * 2
      const distance = Phaser.Math.Between(25, 50)

      // Movimento em espiral
      this.scene.tweens.add({
        targets: particle,
        x: particle.x + Math.cos(angle + Math.PI) * distance,
        y: particle.y + Math.sin(angle + Math.PI) * distance,
        rotation: Math.PI * 2,
        alpha: 0,
        duration: 600,
        ease: "Power2.easeOut",
        onComplete: () => particle.destroy(),
      })
    }
  }

  shootTornado(player) {
    const sprite = this.scene.add.image(this.enemy.x, this.enemy.y, "tornadoProjectile").setScale(0.07)
    this.tornadoes.push({
      sprite,
      createdAt: this.scene.time.now,
    })
  }

  checkCollisionsWithObstacles(proj) {
    return this.scene.obstaculos?.some(
      (ob) => Phaser.Math.Distance.Between(proj.sprite.x, proj.sprite.y, ob.x, ob.y) < 30,
    )
  }

  update(player) {
    const now = this.scene.time.now

    if (this.alive) {
      if (this.moving && now - this.lastMoveToggle > this.moveDuration) {
        this.moving = false
        this.lastMoveToggle = now
      } else if (!this.moving && now - this.lastMoveToggle > this.pauseDuration) {
        this.moving = true
        this.moveDirection = new Phaser.Math.Vector2(
          Phaser.Math.FloatBetween(-1, 1),
          Phaser.Math.FloatBetween(-1, 1),
        ).normalize()
        this.lastMoveToggle = now
      }

      if (this.moving) {
        this.enemy.x += this.moveDirection.x * this.speed
        this.enemy.y += this.moveDirection.y * this.speed

        const bounds = this.scene.gridBounds
        if (this.enemy.x < bounds.left) this.enemy.x = bounds.left
        if (this.enemy.x > bounds.right) this.enemy.x = bounds.right
        if (this.enemy.y < bounds.top) this.enemy.y = bounds.top
        if (this.enemy.y > bounds.bottom) this.enemy.y = bounds.bottom
      } else if (now - this.lastShotTime > this.shootInterval) {
        this.shootTornado(player)
        this.lastShotTime = now
      }
    }

    this.tornadoes.forEach((t, i) => {
      const dx = player.x - t.sprite.x
      const dy = player.y - t.sprite.y
      const len = Math.hypot(dx, dy)
      const vx = (dx / len) * this.tornadoSpeed
      const vy = (dy / len) * this.tornadoSpeed

      t.sprite.x += vx
      t.sprite.y += vy
      t.sprite.flipX = vx < 0

      if (this.checkCollisionsWithObstacles(t)) {
        t.sprite.destroy()
        this.tornadoes.splice(i, 1)
        return
      }

      if (now - t.createdAt > 4000) {
        t.sprite.destroy()
        this.tornadoes.splice(i, 1)
        return
      }

      if (Phaser.Math.Distance.Between(t.sprite.x, t.sprite.y, player.x, player.y) < 35) {
        this.scene.player.takeDamage(this.damage)
        this.scene.showDamage(player.x, player.y - 30, this.damage, "#ff0000", "proj_tornado_" + Math.random())
        t.sprite.destroy()
        this.tornadoes.splice(i, 1)
        return
      }

      const bounds = this.scene.gridBounds
      if (
        t.sprite.x < bounds.left - 30 ||
        t.sprite.x > bounds.right + 30 ||
        t.sprite.y < bounds.top - 30 ||
        t.sprite.y > bounds.bottom + 30
      ) {
        t.sprite.destroy()
        this.tornadoes.splice(i, 1)
      }
    })

    this.hitbox.setPosition(this.enemy.x, this.enemy.y)
    this.updateHealthBar()
  }
}
