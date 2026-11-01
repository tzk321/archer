// src/scenes/MainMenuScene.js

export default class MainMenuScene extends Phaser.Scene {
  constructor() {
    super('MainMenu');
  }

  preload() {
    // Carrega a imagem de fundo para a tela inicial
    this.load.image('background', '/src/assets/inicio.png');
    this.load.image('playButton', '/src/assets/play_button.png');  // Carrega a imagem do botão Jogar
  }

  create() {
    // Define a imagem de fundo da tela inicial, centralizando-a na tela
    this.add.image(this.cameras.main.width / 2, this.cameras.main.height / 2, 'background')
    .setScale(0.45);

    // Cria o botão "Jogar" e o posiciona no centro
    const playButton = this.add.image(this.cameras.main.width / 2, this.cameras.main.height / 1.5, 'playButton')
      .setInteractive()
      .setScale(0.7); // Torna o botão menor, ajustando o fator de escala

    // Adiciona o comportamento de clique no botão "Jogar"
    playButton.on('pointerdown', () => {
      // Ao clicar, o jogo começa
      this.scene.start('GameScene'); // Carregar gameScene
    });
  }
}
