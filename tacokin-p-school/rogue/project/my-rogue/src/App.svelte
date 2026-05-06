<script>
    import kaplay from "kaplay";
    import * as ROT from "rot-js";

    // --- rot.js でデータ作成 ---
    const cols = 18;//横ブロック数
    const rows = 18;//縦ブロック数



    // --- Kaplayを起動

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
    k.loadSprite("stairs", "src/stairs.png");
    k.loadSprite("potion", "src/potion.png");
    k.loadSprite("scroll", "src/scroll.png");

    const TILE_SIZE = 32;
    //マップ配列
    const mapArray = new Array(cols);
    for (let i = 0; i < cols; i++) {
        mapArray[i] = new Array(rows);
    }

    // ダンジョン生成器
    const dungeon = new ROT.Map.Digger(cols, rows, {
        roomWidth: [3, 4],
        roomHeight: [3, 5],
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

    // マップ階層
    let level;

    /** マップを生成・再構築 */
    const setupMap = () => {
        //マップ配列に情報を書き込む
        dungeon.create((x, y, type) => {
            // type: 0=床(.), 1=壁(#)
            mapArray[y][x] = type;
        });
        replaceWall(mapArray);

        // マップデータ（文字列配列）へ変更
        const mapStrings = mapArray.map(row => row.map(cell => {
            return cell == 0 ? "." : cell == 1 ? "#" : cell == 2 ? "=" : "";
        }).join(""));

        if (level != null) level.destroy();
        level = k.addLevel(mapStrings, {
            tileWidth: TILE_SIZE,
            tileHeight: TILE_SIZE,
            tiles: {
                ".": () => [
                    k.sprite("floor", {width: TILE_SIZE, height: TILE_SIZE}),
                    k.opacity(0), // 最初は真っ暗
                    "tile",
                    { seen: false, isWall: false }
                ],
                "#": () => [
                    k.rect(32, 32),
                    k.color(25, 25, 25),
                    "bulk",
                ],
                "=": () => [
                    k.sprite("wall", {width: TILE_SIZE, height: TILE_SIZE}),
                    k.opacity(0), // 最初は真っ暗
                    "wall",
                    "tile",
                    { seen: false, isWall: true }
                ],
            },
        });
    }
    //最初のマップを生成
    setupMap();

    // ----------- 主人公を登場させる

    const rooms = dungeon.getRooms();
    const startPos = rooms[0].getCenter(); // 最初の部屋の真ん中を取得
    const player = k.add([
        k.sprite("player", {width: TILE_SIZE, height: TILE_SIZE}),
        k.pos(startPos[0] * TILE_SIZE, startPos[1] * TILE_SIZE),
        k.area(),
        k.body(),
        k.z(10),
        "player",
        {
            hp: 10,
            maxHp: 10,
            level: 1,
            exp: 0,
            gridX: startPos[0],
            gridY: startPos[1],
        },
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
            case "space":
                // スペースキーで階段を降りる
                const stairs = k.get("stairs").find(s => s.gridX === player.gridX && s.gridY === player.gridY);
                if (stairs) {
                    goToNextFloor();
                    return;
                }
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
            // 攻撃！
            const damage = 1;
            target.hp -= damage;
            addLog("プレイヤーの攻撃！");
            addLog(`モンスターに ${damage} のダメージ！`);

            if (target.hp <= 0) {
                addLog("モンスターをたおした！");
                k.destroy(target); // モンスターを消す
                // 配列からも削除
                const idx = monsters.indexOf(target);
                monsters.splice(idx, 1);

                // 経験値を獲得
                player.exp += 1;
                addLog("1 の経験値を得た！");

                // レベルアップ判定（今回は2経験値ごとにアップ）
                if (player.exp >= player.level * 2) {
                    player.level++;
                    player.maxHp += 2;
                    player.hp = player.maxHp; // 全回復！
                    addLog(`レベルアップ！ レベル ${player.level} になった！`);
                }
            }

            endTurn(); // 自分の攻撃が終わったのでターン終了
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
                player.gridX = Math.floor(player.pos.x / TILE_SIZE);
                player.gridY = Math.floor(player.pos.y / TILE_SIZE);
                // アイテムを拾う
                checkItems();
                // 移動が終わったら敵が動く
                endTurn();
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

            // モンスターを生成
            const monster = k.add([
                k.sprite("monster", {width: TILE_SIZE, height: TILE_SIZE}), // あらかじめ loadSprite しておいてね！
                k.pos(center[0] * TILE_SIZE, center[1] * TILE_SIZE),
                k.area(),
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
    // ゲーム開始にモンスターを配置
    spawnMonsters();

    const moveEnemies = () => {
        // プレイヤーの今の位置（グリッド座標）
        const px = Math.floor(player.pos.x / TILE_SIZE);
        const py = Math.floor(player.pos.y / TILE_SIZE);

        monsters.forEach(m => {
            // 1. ダイクストラ法で「プレイヤーへの道すじ」を計算
            const pather = new ROT.Path.Dijkstra(px, py, (x, y) => {
                // 床(0)なら通れる、壁(1,2)なら通れない
                return mapArray[y]?.[x] === 0;
            }, {
                // 移動方向を4方向に制限する(デフォルトは8方向)
                topology: 4
            });

            const mx = Math.floor(m.pos.x / TILE_SIZE);
            const my = Math.floor(m.pos.y / TILE_SIZE);

            let nextX = mx;
            let nextY = my;

            // 2. モンスターの位置から、次の一歩を教えてもらう
            let path = [];
            pather.compute(mx, my, (x, y) => {
                path.push([x, y]);
            });

            // モンスターから見てプレイヤーまでの最短経路のうち、次のステップ位置(path[1])を取得
            if (path[1] != null) {
                nextX = path[1][0];
                nextY = path[1][1];
            }

            // 3. 次の位置が今の位置と同じなら動かない（道がない時など）
            if (nextX === mx && nextY === my) return;

            // 4. 次の位置にプレイヤーがいたら攻撃！（まだ移動はしない）
            if (nextX === px && nextY === py) {
                addLog("モンスターの攻撃！");
                player.hp -= 1;
                addLog("プレイヤーに 1 のダメージ！");
                k.shake(2); // 画面を揺らしてダメージを表現
                return;
            }

            // 5. スムーズに移動させる
            // モンスターの移動位置
            const _next = k.vec2(nextX * TILE_SIZE, nextY * TILE_SIZE);
            k.tween(m.pos, _next, 0.1, (p) => { m.pos = p; });
        });
    };

    // ----------- UIの作成

    // 1. HPバーの土台（背景のグレー）
    const hpBarBg = k.add([
        k.rect(200, 20),
        k.pos(20, 20),
        k.color(100, 100, 100),
        k.fixed(), // 画面に固定！
        k.z(100),   // 他のキャラより手前に表示
    ]);

    // 2. HPバー本体（赤い部分）
    const hpBar = hpBarBg.add([
        k.rect(200, 20),
        k.color(255, 50, 50),
    ]);

    // 3. メッセージログ用のテキスト
    const messages = [];
    const logText = k.add([
        k.text("", { size: 18, width: 400 }),
        k.pos(20, k.height() - 120),
        k.fixed(),
        k.z(100),
    ]);

    /** ログに新しいメッセージを追加する関数 */
    function addLog(msg) {
        messages.push(msg);
        // 最新の5件だけを表示するようにする
        if (messages.length > 5) messages.shift();
        logText.text = messages.join("\n");
    }

    /** HPバーの見た目を更新する関数 */
    function updateHPBar() {
        // 割合を計算して、赤いバーの長さを変える
        const ratio = player.hp / player.maxHp;
        hpBar.width = 200 * Math.max(0, ratio);
    }

    /** 敵を動かす処理を呼び出す「ターン終了」の合図 */
    function endTurn() {
        moveEnemies(); // 敵が動く
        updateHPBar(); // HPを確認

        if (player.hp <= 0) {
            addLog("ゲームオーバー...");
            k.shake(10);
            // ここでリスタートなどの処理を入れる
        }

        // ターン終了時に階段チェック
        const stairs = k.get("stairs").find(s => s.gridX === player.gridX && s.gridY === player.gridY);
        if (stairs) {
            addLog("階段がある。降りるならスペースキーを押そう！");
        }
    }

    // ----------- アイテムと階段の配置処理

    /** アイテムや階段を作る関数 */
    function spawnFeature(room, type) {
        const x = k.randi(room.getLeft(), room.getRight());
        const y = k.randi(room.getTop(), room.getBottom());

        // その位置にすでに何かがないか確認（床以外ならスキップ）
        // ※ 実際には座標管理用のデータを使ってチェックするのが確実です

        const feature = k.add([
            k.sprite(type, { width: TILE_SIZE, height: TILE_SIZE }),
            k.pos(x * TILE_SIZE, y * TILE_SIZE),
            k.z(0),
            type, // "potion", "scroll", "stairs" などのタグ
            { gridX: x, gridY: y }
        ]);

        return feature;
    }

    // 最初の部屋はプレイヤー用なので、2つ目の部屋以降に配置
    for (let i = 1; i < rooms.length; i++) {
        const room = rooms[i];
        // 30%の確率でポーションを置く
        if (k.chance(0.3)) spawnFeature(room, "potion");
        // 20%の確率で巻物を置く
        if (k.chance(0.2)) spawnFeature(room, "scroll");
    }

    // 最後の部屋に階段を1つ置く
    spawnFeature(rooms[rooms.length - 1], "stairs");

    // 1. Svelteのリアクティブな変数としてインベントリを定義
    let inventory = $state([]);

    /** アイテムを拾う処理 */
    function checkItems() {
        // プレイヤーと同じ位置にあるアイテムを探す
        const items = k.get("potion").concat(k.get("scroll"));
        const item = items.find(i => i.gridX === player.gridX && i.gridY === player.gridY);

        if (item) {
            addLog(`${item.is("potion") ? "ポーション" : "巻物"}を拾った！`);
            // インベントリに追加
            inventory.push({
                id: Date.now(),
                type: item.is("potion") ? "potion" : "scroll",
                name: item.is("potion") ? "回復薬" : "魔法の巻物"
            });
            k.destroy(item); // 画面から消す
        }
    }

    /** アイテムを使う処理 */
    function useItem(index) {
        const item = inventory[index];
        if (item.type === "potion") {
            player.hp = Math.min(player.maxHp, player.hp + 5);
            addLog("体力が 5 回復した！");
        } else {
            addLog("不思議な力が体を包んだ！（効果はこれから！）");
        }
        // インベントリから削除
        inventory.splice(index, 1);
        updateHPBar();
    }

    let floorLevel = 1;

    /** ダンジョンをリセットして新しく作る関数 */
    function goToNextFloor() {
        floorLevel++;
        addLog(`地下 ${floorLevel} 階に降りた。`);

        // 今あるオブジェクト（壁、敵、アイテム）を一旦全部消す
        k.get("wall").forEach(k.destroy);
        k.get("floor").forEach(k.destroy);
        k.get("monster").forEach(k.destroy);
        k.get("potion").forEach(k.destroy);
        k.get("scroll").forEach(k.destroy);
        k.get("stairs").forEach(k.destroy);

        // マップを再生成して描画
        setupMap();

        // プレイヤーを新しい開始位置に移動
        const startPos = dungeon.getRooms()[0].getCenter();
        player.gridX = startPos[0];
        player.gridY = startPos[1];
        player.pos = k.vec2(player.gridX * TILE_SIZE, player.gridY * TILE_SIZE);
        // プレイヤーの再描画
        k.readd(player);

        // ゲーム開始にモンスターを配置
        spawnMonsters();

        // 2つ目の部屋以降にアイテムを配置
        const rooms = dungeon.getRooms();
        for (let i = 1; i < rooms.length; i++) {
            const room = rooms[i];
            // 30%の確率でポーションを置く
            if (k.chance(0.3)) spawnFeature(room, "potion");
            // 20%の確率で巻物を置く
            if (k.chance(0.2)) spawnFeature(room, "scroll");
        }

        // 最後の部屋に階段を1つ置く
        spawnFeature(rooms[rooms.length - 1], "stairs");
    }
</script>

<!-- UI部分：SvelteのHTMLとして記述 -->
<div class="inventory-ui">
    <h3>もちもの</h3>
    <ul>
        {#each inventory as item, i}
            <li>
                {item.name}
                <button onclick={() => useItem(i)}>使う</button>
            </li>
        {/each}
    </ul>
</div>

<style>
    .inventory-ui {
        position: absolute;
        right: 20px;
        top: 20px;
        background: rgba(0, 0, 0, 0.8);
        color: white;
        padding: 10px;
        border: 2px solid #555;
    }
</style>
