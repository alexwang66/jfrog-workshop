const PptxGenJS = require("/tmp/node_modules/pptxgenjs");

const ASSETS = "/Users/qingwang/.claude/skills/jfrog-brand-assets/assets";
const LOGO_G = ASSETS + "/jfrog-logo-green.png";
const LOGO_AR = 166 / 160;
const ICON_ART = ASSETS + "/icon-artifactory.png";

const FONT = "Microsoft YaHei";
const GREEN = "40BE46";
const DGREEN = "2BA318";
const FOREST = "0C2D1A";
const INK = "1A1A1A";
const MUTED = "5F6B62";
const TINT = "EAF7EB";
const TABLE_FILL = "FFC107"; // yellow tables, matching the room photo
const CHAIR = "9E9E9E";

// Room layout: 5 rows, columns seat [2,4,2,4] (alternating small/large tables).
const ROWS = 5;
const COL_SEATS = [2, 4, 2, 4];
const COLS = COL_SEATS.length;
const PLATFORM_URL = process.env.PLATFORM_URL || "〈workshop 平台網址〉";

const pptx = new PptxGenJS();
pptx.defineLayout({ name: "W", width: 13.333, height: 7.5 });
pptx.layout = "W";

const s = pptx.addSlide();
s.background = { color: "FFFFFF" };

// logo top-right on every slide
const lh = 0.42, lw = lh * LOGO_AR;
s.addImage({ path: LOGO_G, x: 13.333 - 0.55 - lw, y: 0.3, w: lw, h: lh });

// title
s.addText(
  [
    { text: "找到你的實驗帳號", options: { bold: true, color: FOREST } },
    { text: "   Find Your Lab Account", options: { bold: true, color: GREEN, fontSize: 18 } },
  ],
  { x: 0.55, y: 0.28, w: 11.0, h: 0.6, fontSize: 26, fontFace: FONT, align: "left", valign: "middle" }
);
s.addShape(pptx.ShapeType.line, { x: 0.6, y: 0.95, w: 12.1, h: 0, line: { color: GREEN, width: 2 } });

// ---------- LEFT: seat map ----------
const mapX = 0.6, mapY = 1.45, mapW = 6.7, mapH = 5.75;

s.addShape(pptx.ShapeType.roundRect, { x: mapX, y: mapY, w: mapW, h: mapH, rectRadius: 0.08,
  fill: { color: "F4FAF5" }, line: { color: CHAIR, width: 1 } });

// screen (blue bar, top)
s.addShape(pptx.ShapeType.roundRect, { x: mapX + mapW * 0.26, y: mapY + 0.12, w: mapW * 0.42, h: 0.12,
  rectRadius: 0.06, fill: { color: "29B6F6" }, line: { type: "none" } });
s.addText("講台螢幕 / Screen", { x: mapX, y: mapY + 0.26, w: mapW, h: 0.22, fontSize: 8,
  color: MUTED, align: "center", fontFace: FONT });

// podium top-right
s.addShape(pptx.ShapeType.roundRect, { x: mapX + mapW - 0.85, y: mapY + 0.5, w: 0.55, h: 0.3,
  rectRadius: 0.04, fill: { color: FOREST }, line: { type: "none" } });
s.addText("講師", { x: mapX + mapW - 0.85, y: mapY + 0.5, w: 0.55, h: 0.3, fontSize: 7,
  color: "FFFFFF", align: "center", valign: "middle", fontFace: FONT });

// table grid
const gridTop = mapY + 1.0;
const gridH = mapH - 1.25;
const cellW = mapW / COLS;
const cellH = gridH / ROWS;
const tH = cellH * 0.34;
const chW = 0.15, chGap = 0.06, pairGap = 0.14;

function drawChairs(cx, topY, seats) {
  // 2 seats -> two adjacent chairs; 4 seats -> 2 + gap + 2
  const positions = [];
  if (seats <= 2) {
    const totalW = seats * chW + (seats - 1) * chGap;
    let x = cx - totalW / 2;
    for (let i = 0; i < seats; i++) { positions.push(x); x += chW + chGap; }
  } else {
    const totalW = 4 * chW + 2 * chGap + pairGap;
    let x = cx - totalW / 2;
    for (let i = 0; i < 4; i++) {
      positions.push(x);
      x += chW + (i === 1 ? pairGap : chGap);
    }
  }
  positions.forEach((x, i) => {
    s.addShape(pptx.ShapeType.roundRect, { x, y: topY, w: chW, h: chW, rectRadius: 0.02,
      fill: { color: CHAIR }, line: { type: "none" } });
    s.addText("" + (i + 1), { x, y: topY, w: chW, h: chW, fontSize: 6, color: "FFFFFF",
      align: "center", valign: "middle", fontFace: FONT });
  });
}

let table = 0;
for (let r = 0; r < ROWS; r++) {
  for (let c = 0; c < COLS; c++) {
    table++;
    const seats = COL_SEATS[c];
    const cx = mapX + c * cellW + cellW / 2;
    const cy = gridTop + r * cellH + cellH * 0.16;
    const tW = (seats >= 4 ? cellW * 0.82 : cellW * 0.46);
    // table rect
    s.addShape(pptx.ShapeType.roundRect, { x: cx - tW / 2, y: cy, w: tW, h: tH, rectRadius: 0.03,
      fill: { color: TABLE_FILL }, line: { color: "E0A800", width: 0.75 } });
    s.addText("T" + table, { x: cx - tW / 2, y: cy, w: tW, h: tH, fontSize: 9, bold: true,
      color: "5A4500", align: "center", valign: "middle", fontFace: FONT });
    drawChairs(cx, cy + tH + 0.06, seats);
  }
}

// bottom door bar (green, matching the photo)
s.addShape(pptx.ShapeType.roundRect, { x: mapX + mapW * 0.26, y: mapY + mapH - 0.18, w: mapW * 0.26, h: 0.08,
  rectRadius: 0.04, fill: { color: GREEN }, line: { type: "none" } });
s.addText("● = 1 個座位　2人桌: S1–S2　4人桌: S1–S4", { x: mapX, y: mapY + mapH - 0.1, w: mapW, h: 0.2,
  fontSize: 8, italic: true, color: MUTED, align: "center", fontFace: FONT });

// ---------- RIGHT: instructions ----------
const px = 7.7, pw = 5.0;

s.addShape(pptx.ShapeType.roundRect, { x: px, y: 1.45, w: pw, h: 2.95, rectRadius: 0.1,
  fill: { color: TINT }, line: { color: GREEN, width: 1 } });
s.addText("三步找到你的帳號", { x: px + 0.25, y: 1.6, w: pw - 0.5, h: 0.4, fontSize: 15, bold: true,
  color: FOREST, fontFace: FONT });
const steps = [
  { n: "1", t: "在座位圖上找到你的桌號  T1 – T20" },
  { n: "2", t: "看桌上標牌確認座位號  S1 / S2 …" },
  { n: "3", t: "帳號 = labuser-t〈桌號〉-s〈座位號〉" },
];
let sy2 = 2.05;
steps.forEach((st) => {
  s.addShape(pptx.ShapeType.ellipse, { x: px + 0.28, y: sy2 + 0.02, w: 0.34, h: 0.34,
    fill: { color: GREEN }, line: { type: "none" } });
  s.addText(st.n, { x: px + 0.28, y: sy2 + 0.02, w: 0.34, h: 0.34, fontSize: 13, bold: true,
    color: "FFFFFF", align: "center", valign: "middle", fontFace: FONT });
  s.addText(st.t, { x: px + 0.75, y: sy2 - 0.04, w: pw - 0.95, h: 0.46, fontSize: 12,
    color: INK, valign: "middle", fontFace: FONT });
  sy2 += 0.66;
});
s.addText(
  [
    { text: "範例：", options: { bold: true, color: DGREEN } },
    { text: "坐在 4 號桌、3 號座 → ", options: { color: INK } },
    { text: "labuser-t4-s3", options: { bold: true, color: FOREST, fontFace: "Consolas" } },
  ],
  { x: px + 0.25, y: 3.92, w: pw - 0.5, h: 0.36, fontSize: 12, fontFace: FONT, valign: "middle" }
);

// credentials card
s.addShape(pptx.ShapeType.roundRect, { x: px, y: 4.6, w: pw, h: 2.05, rectRadius: 0.1,
  fill: { color: FOREST }, line: { type: "none" } });
s.addImage({ path: ICON_ART, x: px + 0.25, y: 4.77, w: 0.32, h: 0.32 });
s.addText("登入資訊 Login", { x: px + 0.65, y: 4.75, w: pw - 0.9, h: 0.36, fontSize: 14, bold: true,
  color: GREEN, valign: "middle", fontFace: FONT });
const cred = [
  { k: "平台網址", v: PLATFORM_URL },
  { k: "帳號", v: "labuser-t〈桌號〉-s〈座位號〉" },
  { k: "密碼（統一）", v: "***REDACTED***" },
];
let cy2 = 5.27;
cred.forEach((c) => {
  s.addText(c.k, { x: px + 0.25, y: cy2, w: 1.5, h: 0.34, fontSize: 11, color: "C8E6C9",
    valign: "middle", fontFace: FONT });
  s.addText(c.v, { x: px + 1.7, y: cy2, w: pw - 1.95, h: 0.34, fontSize: 12, bold: true,
    color: "FFFFFF", valign: "middle", fontFace: "Consolas" });
  cy2 += 0.42;
});

s.addText("登入後請勿修改密碼；如無法登入請聯絡講師。", { x: px, y: 6.8, w: pw, h: 0.4, fontSize: 9.5,
  italic: true, color: MUTED, fontFace: FONT, align: "left", valign: "top" });

const out = "/Users/qingwang/Documents/workspace/code/jfrog-workshop/workshop/lab-account-seatmap.pptx";
pptx.writeFile({ fileName: out }).then(() => console.log("WROTE " + out));
