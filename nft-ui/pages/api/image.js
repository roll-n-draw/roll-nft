const { createCanvas } = require("canvas");

const colors = ["#3A2E39", "#1E555C", "#F4D8CD", "#EDB183", "#F15152", "#F1DEDE", "#D496A7", "#5D576B", "#6CD4FF", "#FE938C"];

export default function handler(req, res) {
  res.setHeader('Content-Type', 'image/jpg');
  res.send(createImage());
}

function createImage() {
  const width = 512;
  const height = 384;
  const canvas = createCanvas(width, height);
  const context = canvas.getContext("2d");
  context.fillStyle = colors[Math.floor(Math.random() * colors.length)];
  context.fillRect(0, 0, width, height);
  context.font = "bold 30px Arial";
  context.textAlign = "center";
  context.fillStyle = "#000000";
  context.fillText("Raffle Sample NFT", width / 2, height / 2);
  const buffer = canvas.toBuffer("image/png");
  return buffer;
}
