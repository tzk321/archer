// src/scenes/WinScene.js


export default class WinScene extends Phaser.Scene {
  constructor() {
    super("WinScene")
  }

  init(data) {
    // Recebe os dados da GameScene
    this.gameTime = data.gameTime || 0
    this.killedMonsters = data.killedMonsters || 0
    this.totalDamage = data.totalDamage || 0
    this.finalPhase = data.finalPhase || 50

    console.log("WinScene dados recebidos:", data)
  }

  create() {
    console.log("WinScene create() chamado")

    // Desfocar camera GameScene
    const gameScene = this.scene.get("GameScene")
    if (gameScene && gameScene.cameras && gameScene.cameras.main) {
      // Adiciona um filtro de blur se disponível, senão usa tint
      gameScene.cameras.main.setTint(0x888888) // Escurece um pouco
    }

    // Overlay de desfoque sobre toda a tela
    const blurOverlay = this.add.rectangle(
      this.cameras.main.centerX,
      this.cameras.main.centerY,
      this.cameras.main.width,
      this.cameras.main.height,
      0x000000,
      0.5,
    )

    // MODAL CENTRAL - Container principal
    const modalWidth = 600
    const modalHeight = 400
    const modalX = this.cameras.main.centerX
    const modalY = this.cameras.main.centerY

    // Sombra da modal
    const modalShadow = this.add.rectangle(modalX + 8, modalY + 8, modalWidth, modalHeight, 0x000000, 0.6)
    modalShadow.setStrokeStyle(0)

    // Fundo da modal
    const modalBg = this.add.rectangle(modalX, modalY, modalWidth, modalHeight, 0x1a1a2e, 0.95)
    modalBg.setStrokeStyle(4, 0xffd700)

    // Título VITÓRIA
    const victoryTitle = this.add
      .text(modalX, modalY - 140, "VITÓRIA!", {
        fontFamily: "Arial Black",
        fontSize: "48px",
        fill: "#FFD700",
        stroke: "#000000",
        strokeThickness: 4,
      })
      .setOrigin(0.5)

    // Subtítulo
    const subtitle = this.add
      .text(modalX, modalY - 100, "Parabéns! Você completou todas as fases!", {
        fontFamily: "Arial",
        fontSize: "20px",
        fill: "#FFFFFF",
        stroke: "#000000",
        strokeThickness: 2,
      })
      .setOrigin(0.5)

    // Título das estatísticas
    this.add
      .text(modalX, modalY - 60, "ESTATÍSTICAS FINAIS", {
        fontFamily: "Arial Black",
        fontSize: "24px",
        fill: "#FFD700",
        stroke: "#000000",
        strokeThickness: 2,
      })
      .setOrigin(0.5)

    // Formatação do tempo
    const formatTime = (seconds) => {
      const mins = Math.floor(seconds / 60)
      const secs = Math.floor(seconds % 60)
      return `${mins}:${secs.toString().padStart(2, "0")}`
    }

    // Estatísticas dentro da modal
    const statsY = modalY - 20
    const lineHeight = 25

    this.add
      .text(modalX, statsY, `🏆 Fases Completas: ${this.finalPhase}`, {
        fontFamily: "Arial",
        fontSize: "18px",
        fill: "#FFFFFF",
        stroke: "#000000",
        strokeThickness: 1,
      })
      .setOrigin(0.5)

    this.add
      .text(modalX, statsY + lineHeight, `⏱️ Tempo Total: ${formatTime(this.gameTime)}`, {
        fontFamily: "Arial",
        fontSize: "18px",
        fill: "#FFFFFF",
        stroke: "#000000",
        strokeThickness: 1,
      })
      .setOrigin(0.5)

    this.add
      .text(modalX, statsY + lineHeight * 2, `💀 Monstros Eliminados: ${this.killedMonsters}`, {
        fontFamily: "Arial",
        fontSize: "18px",
        fill: "#FFFFFF",
        stroke: "#000000",
        strokeThickness: 1,
      })
      .setOrigin(0.5)

    this.add
      .text(modalX, statsY + lineHeight * 3, `⚔️ Dano Total: ${this.totalDamage.toLocaleString()}`, {
        fontFamily: "Arial",
        fontSize: "18px",
        fill: "#FFFFFF",
        stroke: "#000000",
        strokeThickness: 1,
      })
      .setOrigin(0.5)

    // Botões na parte inferior da modal
    const buttonY = modalY + 120

    // Botão Jogar Novamente
    const playAgainBg = this.add.rectangle(modalX - 120, buttonY, 180, 45, 0x2d5a27, 1)
    playAgainBg.setStrokeStyle(3, 0x4caf50)

    const playAgainButton = this.add
      .text(modalX - 120, buttonY, "JOGAR NOVAMENTE", {
        fontFamily: "Arial Black",
        fontSize: "16px",
        fill: "#FFFFFF",
        stroke: "#000000",
        strokeThickness: 2,
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on("pointerdown", () => {
        console.log("Botão Jogar Novamente clicado")
        this.goToGame()
      })
      .on("pointerover", () => {
        playAgainButton.setScale(1.05)
        playAgainBg.setFillStyle(0x4caf50, 1)
      })
      .on("pointerout", () => {
        playAgainButton.setScale(1)
        playAgainBg.setFillStyle(0x2d5a27, 1)
      })

    // Botão Menu Principal
    const mainMenuBg = this.add.rectangle(modalX + 120, buttonY, 160, 45, 0x5a2d27, 1)
    mainMenuBg.setStrokeStyle(3, 0xff6600)

    const mainMenuButton = this.add
      .text(modalX + 120, buttonY, "MENU PRINCIPAL", {
        fontFamily: "Arial Black",
        fontSize: "16px",
        fill: "#FFFFFF",
        stroke: "#000000",
        strokeThickness: 2,
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on("pointerdown", () => {
        console.log("Botão Menu Principal clicado")
        this.goToMainMenu()
      })
      .on("pointerover", () => {
        mainMenuButton.setScale(1.05)
        mainMenuBg.setFillStyle(0xff6600, 1)
      })
      .on("pointerout", () => {
        mainMenuButton.setScale(1)
        mainMenuBg.setFillStyle(0x5a2d27, 1)
      })

    // Animação de entrada da modal
    modalBg.setScale(0)
    modalShadow.setScale(0)
    victoryTitle.setAlpha(0)
    subtitle.setAlpha(0)

    this.tweens.add({
      targets: [modalBg, modalShadow],
      scaleX: 1,
      scaleY: 1,
      duration: 400,
      ease: "Back.easeOut",
    })

    this.tweens.add({
      targets: [victoryTitle, subtitle],
      alpha: 1,
      duration: 600,
      delay: 200,
    })

    // Animação suave do título
    this.tweens.add({
      targets: victoryTitle,
      scaleX: 1.05,
      scaleY: 1.05,
      duration: 2000,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
      delay: 800,
    })

    console.log("WinScene modal criada com sucesso!")
  }

  // FUNÇÃO PARA IR PARA O JOGO (JOGAR NOVAMENTE)
  goToGame() {
    console.log("Indo para GameScene...")

    // Remove o efeito de blur da GameScene
    this.clearGameSceneEffects()

    // Para todas as cenas e inicia GameScene
    this.scene.stop("WinScene") // Para a WinScene
    this.scene.stop("GameScene") // Para a GameScene atual
    this.scene.start("GameScene") // Inicia uma nova GameScene
  }

  // FUNÇÃO PARA IR PARA O MENU PRINCIPAL
  goToMainMenu() {
    console.log("Indo para MainMenu...")

    // Remove o efeito de blur da GameScene
    this.clearGameSceneEffects()

    // Para todas as cenas e inicia MainMenu
    this.scene.stop("WinScene") // Para a WinScene
    this.scene.stop("GameScene") // Para a GameScene
    this.scene.start("MainMenu") // Inicia o MainMenu
  }

  // Limpar efeitos gameScene
  clearGameSceneEffects() {
    const gameScene = this.scene.get("GameScene")
    if (gameScene && gameScene.cameras && gameScene.cameras.main) {
      gameScene.cameras.main.clearTint()
    }
  }

  closeModal() {
    this.clearGameSceneEffects()
    this.scene.stop()
  }
}
