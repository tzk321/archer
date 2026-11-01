// src/arrow.js

export default class Arrow {
  constructor(scene, x, y, target, damage = 200) {
    this.scene = scene
    this.sprite = scene.add.image(x, y, "arrow").setScale(0.12)
    this.sprite.rotation = Phaser.Math.Angle.Between(x, y, target.enemy.x, target.enemy.y)
    this.speed = 400
    this.damage = damage // Dano configurável

    const dx = target.enemy.x - x
    const dy = target.enemy.y - y
    const length = Math.hypot(dx, dy)
    this.velocity = {
      x: (dx / length) * this.speed,
      y: (dy / length) * this.speed,
    }

    this.target = target
  }

  update(time, delta) {
    if (!this.sprite.active) return

    const dt = delta / 1000
    this.sprite.x += this.velocity.x * dt
    this.sprite.y += this.velocity.y * dt

    // Verifica colisão com o alvo
    const dist = Phaser.Math.Distance.Between(this.sprite.x, this.sprite.y, this.target.enemy.x, this.target.enemy.y)

    if (dist < 30 && this.target.health > 0) {
      this.target.takeDamage(this.damage) // Usa o dano configurável

      // Evita mostrar múltiplos textos sobrepostos
      const tag = "arrow_" + this.target.enemy.x + "_" + this.target.enemy.y
      if (!this.scene.shownTexts?.includes(tag)) {
        this.scene.shownTexts = this.scene.shownTexts || []
        this.scene.shownTexts.push(tag)

        this.scene.showDamage(this.target.enemy.x, this.target.enemy.y - 40, this.damage, "#ffffff", tag)
      }

      this.sprite.destroy()
      return
    }

    // Verifica colisão com obstáculos (pedras)
    if (
      this.scene.obstaculos?.some((ob) => Phaser.Math.Distance.Between(this.sprite.x, this.sprite.y, ob.x, ob.y) < 30)
    ) {
      this.sprite.destroy()
      return
    }

    // Remove flechas que saem da tela
    if (
      this.sprite.x < 0 ||
      this.sprite.x > this.scene.cameras.main.width ||
      this.sprite.y < 0 ||
      this.sprite.y > this.scene.cameras.main.height
    ) {
      this.sprite.destroy()
    }
  }
}
