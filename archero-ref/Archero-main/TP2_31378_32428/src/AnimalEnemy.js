// src/AnimalEnemy.js

export default class AnimalEnemy {
  constructor(scene, x, y, key = "animalEnemy") {
    this.scene = scene
    this.enemy = scene.add.image(x, y, key).setScale(0.15)
    this.hitbox = scene.add.ellipse(x, y, 60, 70, 0x808080, 0)
    this.hitbox.setOrigin(0.5, 0.5)

    this.health = 400
    this.maxHealth = 400
    this.speed = 1.5
    this.changeDirectionInterval = 1500
    this.lastDirectionChange = 0

    this.healthBar = scene.add.graphics()
    this.updateHealthBar()

    this.damage = 10
    this.lastDamageTime = 0
    this.invincibleDuration = 200

    // Direção inicial aleatória
    this.direction = new Phaser.Math.Vector2(Phaser.Math.Between(-1, 1), Phaser.Math.Between(-1, 1)).normalize()
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

  // Efeeitos dano
  flashEnhanced() {
    const originalX = this.enemy.x
    const originalY = this.enemy.y
    const originalScale = this.enemy.scaleX

    // Vermelho
    this.enemy.setTint(0xff4444)

    // Tremer
    this.scene.tweens.add({
      targets: this.enemy,
      x: originalX + Phaser.Math.Between(-4, 4),
      y: originalY + Phaser.Math.Between(-4, 4),
      duration: 40,
      yoyo: true,
      repeat: 4,
      onComplete: () => {
        this.enemy.setPosition(originalX, originalY)
      },
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

    // Particulas impacto
    this.createDamageParticles()

    // Remove efeitos após invencibilidade
    this.scene.time.delayedCall(this.invincibleDuration, () => {
      if (this.enemy) {
        this.enemy.clearTint()
      }
    })
  }

  // Particulas de sangue
  createDamageParticles() {
    const particleCount = 5

    for (let i = 0; i < particleCount; i++) {
      // Partículas vermelhas pequenas
      const particle = this.scene.add.circle(
        this.enemy.x + Phaser.Math.Between(-15, 15),
        this.enemy.y + Phaser.Math.Between(-15, 15),
        Phaser.Math.Between(2, 5),
        0xff6666,
      )

      // Movimento das partículas
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

  updateHealthBar() {
    this.healthBar.clear()
    if (this.health < this.maxHealth) {
      this.healthBar.fillStyle(0xff0000, 1)
      this.healthBar.fillRect(this.enemy.x - 30, this.enemy.y - 55, 60 * (this.health / this.maxHealth), 5)
    }
  }

  die(skipCount = false) {
    // Efeito de morte
    this.createDeathEffect()

    this.enemy.destroy()
    this.hitbox.destroy()
    this.healthBar.destroy()
    if (!skipCount) {
      this.scene.monstersKilled++
      this.scene.monstersKilledThisPhase++
    }
  }

  // Efeito visual de morte
  createDeathEffect() {
    // Explosão de partículas de sangue na morte
    for (let i = 0; i < 8; i++) {
      const particle = this.scene.add.circle(this.enemy.x, this.enemy.y, Phaser.Math.Between(3, 8), 0xff0000)

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
  }

  handleCollision(playerHitbox) {
    playerHitbox.takeDamage(this.damage)
  }

  canMoveTo(x, y) {
    return !this.scene.obstaculos?.some((ob) => Phaser.Math.Distance.Between(x, y, ob.x, ob.y) < 30)
  }

  update() {
    const now = this.scene.time.now

    if (now - this.lastDirectionChange > this.changeDirectionInterval) {
      this.direction = new Phaser.Math.Vector2(Phaser.Math.Between(-1, 1), Phaser.Math.Between(-1, 1)).normalize()
      this.lastDirectionChange = now
    }

    const newX = this.enemy.x + this.direction.x * this.speed
    const newY = this.enemy.y + this.direction.y * this.speed

    if (this.canMoveTo(newX, newY)) {
      this.enemy.x = newX
      this.enemy.y = newY
    }

    const bounds = this.scene.gridBounds
    if (this.enemy.x < bounds.left) this.enemy.x = bounds.left
    if (this.enemy.x > bounds.right) this.enemy.x = bounds.right
    if (this.enemy.y < bounds.top) this.enemy.y = bounds.top
    if (this.enemy.y > bounds.bottom) this.enemy.y = bounds.bottom

    this.hitbox.setPosition(this.enemy.x, this.enemy.y)
    this.updateHealthBar()
  }
}
