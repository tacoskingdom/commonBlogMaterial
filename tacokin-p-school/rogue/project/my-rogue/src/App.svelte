<script>
    import kaplay from "kaplay";
    import * as ROT from "rot-js";

    // --- rot.js でデータ作成 ---
    const cols = 18;//横ブロック数
    const rows = 18;//縦ブロック数

    //マップ配列
    const mapArray = new Array(cols);
    for (let i = 0; i < cols; i++) {
        mapArray[i] = new Array(rows);
    }

    const dungeon = new ROT.Map.Digger(cols, rows);
    //マップ配列に情報を書き込む
    dungeon.create((x, y, type) => {
        // type: 0=床(.), 1=壁(#)
        mapArray[x][y] = type;
    });

    //床(0)に隣接した壁を2へ変更
    const checkWall = (map) => {
        for (let i=1; i< map.length-1; i++) {
            for (let j=1; j< map[i].length-1; j++) {
                if (map[i][j] == 0) {
                    if (map[i-1][j] == 1) map[i-1][j] = 2;
                    if (map[i-1][j-1] == 1) map[i-1][j-1] = 2;
                    if (map[i+1][j] == 1) map[i+1][j] = 2;
                    if (map[i-1][j+1] == 1) map[i-1][j+1] = 2;
                    if (map[i][j-1] == 1) map[i][j-1] = 2;
                    if (map[i+1][j-1] == 1) map[i+1][j-1] = 2;
                    if (map[i][j+1] == 1) map[i][j+1] = 2;
                    if (map[i+1][j+1] == 1) map[i+1][j+1] = 2;
                }
            }
        }
    };
    checkWall(mapArray);

    // マップデータ（文字列配列）へ変更
    const mapStrings = mapArray.map(row => row.map(cell => {
        return cell == 0 ? "." : cell == 1 ? "#" : cell == 2 ? "=" : "";
    }).join(""));

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
                "floor",
            ],
            "#": () => [
                k.rect(32, 32),
                k.color(25, 25, 25),
                "bulk",
            ],
            "=": () => [
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
        k.body(),
        "player",
    ]);

    const checkForward = (x, y) => {
        const objects = level.get("wall");
        const targetObj = objects.find(obj => {
            return obj.pos.x == x && obj.pos.y == y
        });

        if (targetObj) {
            // オブジェクトが見つかった場合true
            return true;
        }
        return false;
    }

    let lock = false;

    k.onKeyPress("left", () => {
        const anchor = player.pos.add(-TILE_SIZE, 0);
        if (checkForward(anchor.x, anchor.y)) return;
        player.pos.x -= TILE_SIZE;
        // lock = true;
        // k.tween(player.pos, anchor, 0.2, (p) => {
        //     player.pos = p;
        //     if (p == anchor) lock = false;
        // }, k.easings.linear);
    });

    k.onKeyPress("right", () => {
        const anchor = player.pos.add(TILE_SIZE, 0);
        if (checkForward(anchor.x, anchor.y)) return;
        player.pos.x += TILE_SIZE;
        // k.tween(player.pos, anchor, 0.2, (p) => player.pos = p, k.easings.linear);
    });

    k.onKeyPress("up", () => {
        const anchor = player.pos.add(0, -TILE_SIZE);
        if (checkForward(anchor.x, anchor.y)) return;
        player.pos.y -= TILE_SIZE;
        // k.tween(player.pos, anchor, 0.2, (p) => player.pos = p, k.easings.linear);
    });

    k.onKeyPress("down", () => {
        const anchor = player.pos.add(0, TILE_SIZE);
        if (checkForward(anchor.x, anchor.y)) return;
        player.pos.y += TILE_SIZE;
        // k.tween(player.pos, anchor, 0.2, (p) => player.pos = p, k.easings.linear);
    });

</script>
