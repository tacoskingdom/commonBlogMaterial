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
        // mapArray[x][y] = type;
        mapArray[y][x] = type;
    });

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
    k.loadSprite("monster", "src/slime.png");

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
                // k.opacity(0), // 最初は真っ暗
                // "tile",
                // { seen: false, isWall: true }
            ],
            "=": () => [
                k.sprite("wall", {width: 32, height: 32}),
                k.opacity(0), // 最初は真っ暗
                "wall",
                "tile",
                { seen: false, isWall: true }
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

        // 移動先にモンスターがいるかチェック

        const tx = anchor.x / TILE_SIZE;
        const ty = anchor.y / TILE_SIZE;
        const target = monsters.find(m =>
            Math.floor(m.pos.x / TILE_SIZE) === tx && 
            Math.floor(m.pos.y / TILE_SIZE) === ty
        );

        if (target) {
            // モンスターがいたら攻撃！
            target.hp -= 1;
            k.debug.log(`モンスターにダメージ！ 残りHP: ${target.hp}`);

            // 攻撃の演出（少しだけ揺らす）
            k.shake(1);

            if (target.hp <= 0) {
                k.destroy(target); // モンスターを消す
                // 配列からも削除
                const idx = monsters.indexOf(target);
                monsters.splice(idx, 1);
            }

            // 攻撃した後は、敵のターンへ
            moveEnemies();
            return;
        }

        // 壁がなければ移動
        if (!checkForward(anchor.x, anchor.y)) {
            const interval = 0.3;
            lock = true;

            k.tween(player.pos, anchor, interval, (p) => {
                player.pos = p;
            }, k.easings.linear).onEnd(() => {
                lock = false;
                k.debug.log("移動完了！");
                // 移動が終わったら敵が動く
                moveEnemies();
            });
        }
    });

    // 視界の広さを決める（160ピクセル ＝ タイル5枚分くらい）
    const VISION_RADIUS = 160;

    // 全てのタイルに対して、プレイヤーとの距離をチェックする
    k.onUpdate("tile", (t) => {
        // 1. プレイヤーとタイルの距離（ピクセル）を計算
        const d = t.pos.dist(player.pos);

        if (d < VISION_RADIUS) {
            // 2. 視界内：ハッキリ見える
            t.opacity = 1;
            t.color = k.rgb(255, 255, 255);
            t.seen = true; // 探索済みにする
        } else if (t.seen) {
            // 3. 探索済み：一度見た場所は「薄暗く」表示
            t.opacity = 0.4;
            t.color = k.rgb(100, 100, 150); // 少し青みがけると雰囲気が出る！
        } else {
            // 4. 未探索：まだ見ていない場所は真っ暗
            t.opacity = 0;
        }
    });

    // ----------- Monsters!

    const monsters = [];

    const spawnMonsters = () => {
        const rooms = dungeon.getRooms();

        // 最初の部屋（プレイヤーがいる部屋）以外にモンスターを配置
        for (let i = 1; i < rooms.length; i++) {
            const center = rooms[i].getCenter();
            k.debug.log(center[0], center[1]);
            // モンスターを生成
            const monster = k.add([
                k.sprite("monster"), // あらかじめ loadSprite しておいてね！
                k.pos(center[0] * TILE_SIZE, center[1] * TILE_SIZE),
                k.area(),
                // k.body(),
                "monster",
                {
                    hp: 3, // 体力
                    gridX: center[0],
                    gridY: center[1]
                }
            ]);
            monsters.push(monster);
        }
    };

    spawnMonsters();

    const moveEnemies = () => {
        // プレイヤーの今の位置（グリッド座標）
        const px = Math.floor(player.pos.x / TILE_SIZE);
        const py = Math.floor(player.pos.y / TILE_SIZE);

        monsters.forEach(m => {
            // 1. ダイクストラ法で「プレイヤーへの道」を計算
            const pather = new ROT.Path.Dijkstra(px, py, (x, y) => {
                // 床(0)なら通れる、壁(1,2)なら通れない
                return mapArray[y]?.[x] === 0;
            }, {
                topology: 4
            });

            const mx = Math.floor(m.pos.x / TILE_SIZE);
            const my = Math.floor(m.pos.y / TILE_SIZE);

            let nextX = mx;
            let nextY = my;
            let path = [];
            // 2. モンスターの位置から、次の一歩を教えてもらう
            pather.compute(mx, my, (x, y) => {
                console.log("動き？", `${mx} -> ${x}`, `${my} -> ${y}`);
                path.push([x, y]);
            });
            if (path[1] != null) {
                nextX = path[1][0];
                nextY = path[1][1];
            }
            k.debug.log("モンスターの移動", nextX, nextY);

            // 3. 次の位置が今の位置と同じなら動かない（道がない時など）
            if (nextX === mx && nextY === my) return;

            // 4. 次の位置にプレイヤーがいたら攻撃！（まだ移動はしない）
            if (nextX === px && nextY === py) {
                k.debug.log("モンスターの攻撃！");
                k.shake(2); // 画面を揺らしてダメージを表現
                return;
            }

            // 5. スムーズに移動させる
            k.debug.log("モンスター位置", m.pos);
            const _next = k.vec2(nextX * TILE_SIZE, nextY * TILE_SIZE);
            k.debug.log("モンスター移動位置", _next);
            k.tween(m.pos, _next, 0.1, (p) => {
                m.pos = p;
            });
        });
    };




</script>
