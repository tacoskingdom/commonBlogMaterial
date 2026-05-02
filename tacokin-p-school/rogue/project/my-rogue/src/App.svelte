<script>
    import kaplay from "kaplay";
    import * as ROT from "rot-js";

    // 1. KAPLAY を初期化（しょきか）します
    const k = kaplay({
        width: 640,
        height: 480,
        background: [20, 20, 20], // 暗い灰色の背景
    });

    // 1. 画像を読み込みます（loadSprite）
    // player.png というファイルを "player" という名前で使う宣言です
    k.loadSprite("player", "src/player.png");

    // 1マスのサイズを 32ピクセル に決めます
    const TILE_SIZE = 32;

    // 2. 主人公を画面に登場させます（add）
    const player = k.add([
        k.sprite("player", { width: TILE_SIZE, height: TILE_SIZE }),       // さっき読み込んだ画像を使う
        k.pos(k.center()),       // 画面の真ん中に置く
        k.anchor("center"),     // キャラクターの真ん中を基準にする
        "player",               // このオブジェクトに "player" という名前（タグ）をつける
    ]);


    // 左キーが押されたとき
    k.onKeyPress("left", () => {
        player.pos.x -= TILE_SIZE; // 左に 32px 移動
    });

    // 右キーが押されたとき
    k.onKeyPress("right", () => {
        player.pos.x += TILE_SIZE; // 右に 32px 移動
    });

    // 上キーが押されたとき
    k.onKeyPress("up", () => {
        player.pos.y -= TILE_SIZE; // 上に 32px 移動
    });

    // 下キーが押されたとき
    k.onKeyPress("down", () => {
        player.pos.y += TILE_SIZE; // 下に 32px 移動
    });
</script>
