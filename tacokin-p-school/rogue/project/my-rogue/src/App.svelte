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

    const dungeon = new ROT.Map.Digger(cols, rows, {
        roomWidth: [3, 4],
        roomHeight: [3, 5],
    });
    //マップ配列に情報を書き込む
    dungeon.create((x, y, type) => {
        // type: 0=床(.), 1=壁(#)
        mapArray[x][y] = type;
    });

    const sourceMap = [...mapArray];

    //床(0)に隣接した壁(2)へ変更
    const replaceWall = (map) => {
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
    replaceWall(mapArray);

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
                k.opacity(0), // 最初は真っ暗
                "tile",
                { seen: false, isWall: false }
            ],
            "#": () => [
                k.rect(32, 32),
                k.color(25, 25, 25),
                "bulk",
                k.opacity(0), // 最初は真っ暗
                "tile",
                { seen: false, isWall: false }
            ],
            "=": () => [
                k.sprite("wall", {width: 32, height: 32}),
                k.opacity(0), // 最初は真っ暗
                "wall",
                "tile",
                { seen: false, isWall: false }
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
        return !!targetObj; // 壁があれば true, なければ false
    }

    let lock = false;

    k.onKeyPress((key) => {
        if (lock) return;

        let anchor = player.pos;
        switch(key) {
            case "left":
                anchor = anchor.add(-TILE_SIZE, 0);
                break;
            case "right":
                anchor = anchor.add(TILE_SIZE, 0);
                break;
            case "up":
                anchor = anchor.add(0, -TILE_SIZE);
                break;
            case "down":
                anchor = anchor.add(0, TILE_SIZE);
                break;
            default:
                return;
        }

        if (checkForward(anchor.x, anchor.y)) return;

        const interval = 0.3;
        lock = true;
        // 移動が終わったタイミング、または移動アニメーションの開始時に実行
        updateFov();
        k.tween(player.pos, anchor, interval, (p) => {
            player.pos = p;
        }, k.easings.linear).onEnd(() => {
            lock = false;
            k.debug.log("移動完了！");
            updateFov();
        });
    });


    // 1. 視界計算の準備（光を通すかどうかの判定）
    const fov = new ROT.FOV.PreciseShadowcasting((x, y) => {
        // mapArray は第3回で作ったマップデータ（0=床, 1=壁）
        // 床(0)なら光を通す
        // return mapArray[x]?.[y] === 0; 
        return sourceMap[x]?.[y] === 0; 
    });

    // 2. 視界を更新する関数
    const updateFov = () => {
        // 現在の視界をリセット（すべて見えない状態にする）
        const allTiles = level.get("tile");
        allTiles.forEach(t => {
            t.visible = false; // KAPLAYの表示フラグ
        });

        // プレイヤーのグリッド座標を取得（TILE_SIZEで割る）
        const px = Math.floor(player.pos.x / TILE_SIZE);
        const py = Math.floor(player.pos.y / TILE_SIZE);

        // 3. 半径6マスの範囲で視界を計算
        fov.compute(px, py, 6, (x, y, r, visibility) => {
            if (visibility > 0) {
                // 視界に入ったタイルを探す
                const tilesAtPos = allTiles.filter(t => 
                    Math.floor(t.pos.x / TILE_SIZE) === x && 
                    Math.floor(t.pos.y / TILE_SIZE) === y
                );

                tilesAtPos.forEach(t => {
                    t.visible = true; // 今見えている
                    t.seen = true;    // 一度見た！
                });
            }
        });

        // 4. 見た目に反映させる
        allTiles.forEach(t => {
            if (t.visible) {
                t.opacity = 1; // 視界内はハッキリ
                t.color = k.WHITE;
            } else if (t.seen) {
                t.opacity = 0.3; // 探索済みは薄暗く
                t.color = k.rgb(100, 100, 150); // 少し青みがけるとかっこいい！
            } else {
                t.opacity = 0; // 未探索は真っ暗
            }
        });
    };

    updateFov();

</script>
