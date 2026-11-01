// src/StoneShooterEnemy.js

export default class StoneShooterEnemy {
  constructor(scene, x, y, key = "stoneEnemy") {
    this.scene = scene
    this.enemy = scene.add.image(x, y, key).setScale(0.11)
    this.hitbox = scene.add.ellipse(x, y, 60, 70, 0x888888, 0).setOrigin(0.5, 0.5)

    this.health = 600
    this.maxHealth = 600
    this.healthBar = scene.add.graphics()
    this.updateHealthBar()

    this.damage = 20
    this.lastDamageTime = 0
    this.invincibleDuration = 200

    this.shootInterval = 2500
    this.lastShotTime = 0

    this.projectiles = []
    this.projectileSpeed = 2

    this.moving = true
    this.moveDuration = 1000
    this.pauseDuration = 1500
    this.lastMoveToggle = scene.time.now

    this.moveDirection = new Phaser.Math.Vector2(
      Phaser.Math.FloatBetween(-1, 1),
      Phaser.Math.FloatBetween(-1, 1),
    ).normalize()
    this.speed = 1.2

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

    this.enemy.setTint(0xffaaaa)

    // tremer
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

    // Pulsação
    this.scene.tweens.add({
      targets: this.enemy,
      scaleX: originalScale * 1.02,
      scaleY: originalScale * 1.02,
      duration: 150,
      yoyo: true,
      ease: "Power2",
    })

    // particulas pedra
    this.createStoneChips()

    // Efeito explosão pedra
    this.createStoneExplosion()

    this.scene.time.delayedCall(this.invincibleDuration, () => {
      if (this.enemy) {
        this.enemy.clearTint()
      }
    })
  }

  // Criar partículas para simular a explosão do monstro da pedra
  createStoneExplosion() {
    const particleCount = 10

    for (let i = 0; i < particleCount; i++) {
      const particle = this.scene.add.circle(
        this.enemy.x + Phaser.Math.Between(-15, 15),
        this.enemy.y + Phaser.Math.Between(-15, 15),
        Phaser.Math.Between(2, 5),
        0x696969,
      )

      const angle = Phaser.Math.Between(0, 360)
      const distance = Phaser.Math.Between(20, 40)
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

  // Função de morte com expansão e explosão
  die(skipCount = false) {
    this.alive = false
    this.isDying = true

    // Limpar todos os projéteis quando morrer
    this.projectiles.forEach((proj) => {
      if (proj.circle) {
        proj.circle.destroy()
      }
    })
    this.projectiles = [] // Limpa o array

    // Expansão do inimigo antes de explodir
    this.scene.tweens.add({
      targets: this.enemy,
      scaleX: this.enemy.scaleX * 1.1,
      scaleY: this.enemy.scaleY * 1.1,
      duration: 200,
      onComplete: () => {
        this.createDeathEffect()
      },
    })

    if (!skipCount) {
      this.scene.monstersKilled++
      this.scene.monstersKilledThisPhase++
    }
  }

  // Efeito visual de morte
  createDeathEffect() {
    // Explosão de partículas de pedra na morte
    for (let i = 0; i < 8; i++) {
      const particle = this.scene.add.circle(this.enemy.x, this.enemy.y, Phaser.Math.Between(3, 8), 0x696969) // Cor de pedra

      const angle = (i / 8) * Math.PI * 2
      const distance = Phaser.Math.Between(30, 60)

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

    // Flash de morte
    const deathFlash = this.scene.add.circle(this.enemy.x, this.enemy.y, 40, 0xffffff, 0.8)
    this.scene.tweens.add({
      targets: deathFlash,
      scaleX: 2,
      scaleY: 2,
      alpha: 0,
      duration: 300,
      onComplete: () => deathFlash.destroy(),
    })

    // Remover o inimigo após a explosão
    this.enemy.destroy()
    this.hitbox.destroy()
    this.healthBar.destroy()
  }

  createStoneChips() {
    // Criar lascas de pedra ao ser atingido
    for (let i = 0; i < 3; i++) {
      const chip = this.scene.add.rectangle(
        this.enemy.x + Phaser.Math.Between(-10, 10),
        this.enemy.y + Phaser.Math.Between(-10, 10),
        Phaser.Math.Between(2, 3),
        Phaser.Math.Between(2, 3),
        0x696969,
      )

      const angle = Phaser.Math.Between(0, 360)
      const distance = Phaser.Math.Between(10, 20)

      this.scene.tweens.add({
        targets: chip,
        x: chip.x + Math.cos(angle) * distance,
        y: chip.y + Math.sin(angle) * distance,
        rotation: Phaser.Math.Between(0, Math.PI),
        alpha: 0,
        scaleX: 0.1,
        scaleY: 0.1,
        duration: 300,
        ease: "Power2.easeOut",
        onComplete: () => chip.destroy(),
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

  shootProjectiles() {
    if (!this.alive || this.isDying) return

    for (let i = 0; i < 3; i++) {
      const angle = Phaser.Math.FloatBetween(0, Math.PI * 2)
      const vx = Math.cos(angle) * this.projectileSpeed
      const vy = Math.sin(angle) * this.projectileSpeed

      const proj = {
        circle: this.scene.add.circle(this.enemy.x, this.enemy.y, 6, 0x5e4b3c),
        vx,
        vy,
        bounces: 0,
      }

      this.projectiles.push(proj)
    }
  }

  checkCollisionsWithObstacles(proj) {
    return this.scene.obstaculos?.some(
      (ob) => Phaser.Math.Distance.Between(proj.circle.x, proj.circle.y, ob.x, ob.y) < 30,
    )
  }

  update(player) {
    if (!this.alive || this.isDying) {
      // Se estiver a morrer, limpa projéteis restantes
      if (this.isDying && this.projectiles.length > 0) {
        this.projectiles.forEach((proj) => {
          if (proj.circle) {
            proj.circle.destroy()
          }
        })
        this.projectiles = []
      }
      return
    }

    const now = this.scene.time.now

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
      this.shootProjectiles()
      this.lastShotTime = now
    }

    const bounds = this.scene.gridBounds
    this.projectiles.forEach((proj, index) => {
      proj.circle.x += proj.vx
      proj.circle.y += proj.vy

      if (this.checkCollisionsWithObstacles(proj)) {
        proj.circle.destroy()
        this.projectiles.splice(index, 1)
        return
      }

      const rebounded =
        proj.circle.x < bounds.left ||
        proj.circle.x > bounds.right ||
        proj.circle.y < bounds.top ||
        proj.circle.y > bounds.bottom

      if (rebounded && proj.bounces < 3) {
        if (proj.circle.x < bounds.left || proj.circle.x > bounds.right) proj.vx *= -1
        if (proj.circle.y < bounds.top || proj.circle.y > bounds.bottom) proj.vy *= -1
        proj.bounces++
      } else if (proj.bounces >= 3) {
        proj.circle.destroy()
        this.projectiles.splice(index, 1)
        return
      }

      if (Phaser.Math.Distance.Between(proj.circle.x, proj.circle.y, player.x, player.y) < 30) {
        this.scene.player.takeDamage(this.damage)
        this.scene.showDamage(player.x, player.y - 30, this.damage, "#ff0000", "proj_stone_" + Math.random())
        proj.circle.destroy()
        this.projectiles.splice(index, 1)
      }
    })

    this.hitbox.setPosition(this.enemy.x, this.enemy.y)
    this.updateHealthBar()
  }
}