<script>
    import kaplay from "kaplay";
    import * as ROT from "rot-js";

    // --- rot.js でデータ作成 ---
    const cols = 18;//横ブロック数
    const rows = 18;//縦ブロック数

    let mapStrings = [];
    const dungeon = new ROT.Map.Digger(cols, rows);
    dungeon.create((x, y, value) => {
        if (!mapStrings[y]) mapStrings[y] = "";
        // value 0=床(.), 1=壁(#)
        mapStrings[y] += (value === 0 ? "." : "#");
    });
    console.log('[Info]dungeon:', dungeon);

    const k = kaplay({
        width: 32*cols,
        height: 32*rows,
        background: [20, 20, 20],
    });

    // 素材の読み込み
    k.loadSprite("floor", "src/floor.png");
    k.loadSprite("wall", "src/wall.png");
    k.loadSprite("player", "src/player.png");

    const TILE_SIZE = 32;

    // --- KAPLAY の addLevel で一気に描画 ---
    const level = k.addLevel(mapStrings, {
        tileWidth: TILE_SIZE,
        tileHeight: TILE_SIZE,
        tiles: {
            ".": () => [
                k.sprite("floor", {width: 32, height: 32}),
                // k.area(),
                "floor",
            ],
            "#": () => [
                k.sprite("wall", {width: 32, height: 32}),
                // k.area(),
                // k.body({ isStatic: true }), // 壁は動かない＆ぶつかる
                "wall",
            ],
        },
    });

    // 主人公を床の上に登場させる
    const rooms = dungeon.getRooms();
    const startPos = rooms[0].getCenter(); // 最初の部屋の真ん中を取得
    const player = k.add([
        k.sprite("player", {width: 32, height: 32}),
        k.pos(startPos[0] * TILE_SIZE, startPos[1] * TILE_SIZE),
        k.area(),
        // k.body(),
        "player",
    ]);

    k.onKeyPress("left", () => {
        player.pos.x -= TILE_SIZE;
        // player.move(-600, 0);
    });

    k.onKeyPress("right", () => {
        player.pos.x += TILE_SIZE;
        // player.move(600, 0);
    });

    k.onKeyPress("up", () => {
        player.pos.y -= TILE_SIZE;
        // player.move(0, -600);
    });

    k.onKeyPress("down", () => {
        player.pos.y += TILE_SIZE;
        // player.move(0, 600);
    });

</script>
