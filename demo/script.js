// 漢字入力システム (direct-input23.ahk) デモサイト用スクリプト
//   Version: 0.1.0
//   製作: kouie

// グローバル変数
let inputBuffer = "";       // 変換用バッファ
let dictionaries = {        // 辞書セット
    "kanji": {},            // 漢字辞書
    "katakana": {}          // カタカナ辞書
};
let currentDictionary = "kanji";  // 現在使用中の辞書タイプ
let dictionary = {};        // 現在使用中の辞書
let matchCount = 0;         // マッチカウント
let lastFixKey = "";        // 最後に変換したキー
let lastFixKey2 = "";       // 一つ前に変換したキー
let reConAble = 0;          // 再変換可能フラグ
let isActive = true;        // システム有効/無効フラグ
let isBackspacePressed = false; // バックスペース検出フラグ
let currentMessageTimer = null; // タイマーIDを保持する変数

// 入力対象データ
let targetData = {
    "names-kanji": [
        { text: "長谷川 今日子", kana: "ハセガワ キョウコ" },
        { text: "田中 京子", kana: "タナカ キョウコ" },
        { text: "佐藤 健太", kana: "サトウ ケンタ" },
        { text: "鈴木 花子", kana: "スズキ ハナコ" },
        { text: "高橋 誠", kana: "タカハシ マコト" },
        { text: "渡辺 直美", kana: "ワタナベ ナオミ" },
        { text: "伊藤 剛", kana: "イトウ ツヨシ" },
        { text: "山本 裕子", kana: "ヤマモト ユウコ" },
        { text: "中村 大輔", kana: "ナカムラ ダイスケ" },
        { text: "小林 美咲", kana: "コバヤシ ミサキ" },
        { text: "加藤 浩二", kana: "カトウ コウジ" }
    ],
    "names-katakana": [
        { text: "タナカ イチロウ", kana: "田中 一郎" },
        { text: "サトウ ケンタ", kana: "佐藤 健太" },
        { text: "スズキ ハナコ", kana: "鈴木 花子" },
        { text: "タカハシ マコト", kana: "高橋 誠" },
        { text: "ワタナベ ナオミ", kana: "渡辺 直美" },
        { text: "イトウ ツヨシ", kana: "伊藤 剛" },
        { text: "ヤマモト ユウコ", kana: "山本 裕子" },
        { text: "ナカムラ ダイスケ", kana: "中村 大輔" },
        { text: "コバヤシ ミサキ", kana: "小林 美咲" },
        { text: "カトウ コウジ", kana: "加藤 浩二" }
    ],
    "addresses": [
        { text: "東京都新宿区", kana: "トウキョウト シンジュクク" },
        { text: "大阪府大阪市", kana: "オオサカフ オオサカシ" },
        { text: "京都府京都市", kana: "キョウトフ キョウトシ" },
        { text: "北海道札幌市", kana: "ホッカイドウ サッポロシ" },
        { text: "福岡県博多区", kana: "フクオカケン ハカタク" },
        { text: "愛知県名古屋市", kana: "アイチケン ナゴヤシ" },
        { text: "神奈川県横浜市", kana: "カナガワケン ヨコハマシ" },
        { text: "広島県広島市", kana: "ヒロシマケン ヒロシマシ" },
        { text: "宮城県仙台市", kana: "ミヤギケン センダイシ" },
        { text: "兵庫県神戸市", kana: "ヒョウゴケン コウベシ" }
    ]
};

let dictionaryForDataset = {
    "names-kanji": "kanji",
    "names-katakana": "katakana",
    "addresses": "kanji",
    "tutorial" : "tutorial"
};

let infoForDataset = {
    "names-kanji": { "dic": "kanji", "probIndex": 0 },
    "names-katakana": { "dic": "katakana", "probIndex": 0 },
    "addresses": { "dic": "kanji", "probIndex": 0 },
    "tutorial": { "dic": "tutorial", "probIndex": 0 }
};

// 許可する type のリスト
const ALLOWED_TYPES = ["message"];        

let currentDataSet = "names-kanji"; // 現在のターゲットデータセット
let currentTargetIndex = 0;     // 現在の入力対象インデックス (どこまで進んだか)
let currentTarget = null;       // 現在の入力対象
let completedReadings = [];     // 入力済みの読み単位（インデックス）
let checkingIndex = 0;
let currentTargetReadings = []; // 現在の入力対象の読み単位の配列
let currentCompletedTarget = "" // 入力完了 (隠れ読みに対応するなら)

// DOM要素
const inputField = document.getElementById('inputField');
const inputDisplay = document.getElementById('inputDisplay');
const messageArea = document.getElementById('messageArea');
const toggleButton = document.getElementById('toggleSystem');
const nextTargetButton = document.getElementById('nextTarget');
const clearInputButton = document.getElementById('clearInput');
const targetTextElement = document.getElementById('targetText');
const targetReadingElement = document.getElementById('targetReading');
const dictionaryTypeSelect = document.getElementById('dictionaryType');
const dictionaryFileInput = document.getElementById('dictionaryFile');
const problemsFileInput = document.getElementById('problemsFile');
const loadDictionaryButton = document.getElementById('loadDictionary');
const loadProblemsButton = document.getElementById('loadProblems');
const dictionaryNameInput = document.getElementById('dictionaryName');
const problemsNameInput = document.getElementById('problemsName');

let tabs = document.querySelectorAll('.tab');

// サンプル漢字辞書データ
const sampleKanjiDictionary = {
    // 単漢字
    "tn": "田", "nk": "中", "it": "一", "rj": "郎",
    "sl": "佐", "fj": "藤", "kn": "健", "df": "太",
    "b88": "鈴", "wt": "渡", "bb": "美", "dd": "大",
    "kf": "花", "vv": "子", "tt": "高", "kx": "小",
    "ng": "長", "tv": "谷", "kw": "川",
    // 複合
    "tan": "田中", "ir": "一郎", "sp": "佐藤", 
    "b8": "鈴木", "kfv": "花子", "th": "高橋", "kob": "小林",
    "has":"長谷", "tak": "谷川",
    // 住所
    "tky": "東京", "osk": "大阪", "kyt": "京都", "hkd": "北海道",
    "fk": "福岡", "ai": "愛知", "kng": "神奈川", "hrs": "広島",
    "mg": "宮城", "hg": "兵庫", "sjk": "新宿", "hkt": "博多",
    "spr": "札幌", "ngy": "名古屋", "yhm": "横浜", "snd": "仙台",
    "kb": "神戸"
};

// サンプルカタカナ辞書データ
const sampleKatakanaDictionary = {
    "tn": "タナカ", "ir": "イチロウ", "st": "サトウ", "kt": "ケンタ",
    "szk": "スズキ", "hk": "ハナコ", "tah": "タカハシ", "mt": "マコト",
    "wtb": "ワタナベ", "nm": "ナオミ", "it": "イトウ", "ts": "ツヨシ",
    "ymt": "ヤマモト", "yk": "ユウコ", "nkm": "ナカムラ", "ds": "ダイスケ",
    "kby": "コバヤシ", "msk": "ミサキ", "kto": "カトウ", "kj": "コウジ",
    "tky": "トウキョウト", "sjk": "シンジュクク", "osk": "オオサカ", 
    "kyt": "キョウト", "hkd": "ホッカイドウ", "spr": "サッポロ",
    "fk": "フクオカ", "hkt": "ハカタ", "ai": "アイチ", "ngy": "ナゴヤ",
    "kng": "カナガワ", "ykh": "ヨコハマ", "hrs": "ヒロシマ", 
    "mg": "ミヤギ", "snd": "センダイ", "hg": "ヒョウゴ", "kb": "コウベ"
};

// 辞書の初期化

// ファイル読み込み関数をPromiseを返すように変更
function initialProbelmLoad(filePath) {
    const customProblems = [];
    return fetch(filePath)
        .then(response => response.text())
        .then(text => {
            // テキストを処理してデータ構造に変換
            const lines = text.split('\n').filter(line => line.trim() !== '');
            const result = lines.map(line => parseLine(line));

            return result;
        })
        .catch(error => {
            console.error('ファイル読み込みエラー:', error);
        });
}

// 1行のテキストをパースして指定の形式のオブジェクトを返す関数
function parseLine(line) {
    // カンマが存在するかチェック
    
    const commaIndex = line.indexOf(',');
    let text = ""
    let objStr = ""
    if (commaIndex === -1) {
        // カンマがない場合は行全体をtextとして登録
        text = line.trim();
        const remainingPart = ""
        objStr = `{\"text\": \"${text}\", \"events\": [], \"id\": ""}`;
//                objStr = `{\"text\": \"${text}\"}`;
    } else {
        // カンマがある場合は、カンマまでをtextとして取得
        text = line.substring(0, commaIndex).trim();
        const remainingPart = line.substring(commaIndex + 1).trim();
        objStr = `{\"text\": \"${text}\", ${remainingPart}}`;
        string = JSON.parse(objStr);
    }

    try {
        const parsedString = processUserData(objStr);

        if (parsedString.valid === true) {
            return parsedString.data;
        }else{
            return {"text": text, "events": []};             
        }

    } catch (error) {
        console.error('プロパティの解析に失敗しました:', error);
        // エラーが発生した場合は、テキスト部分だけを含むオブジェクトを返す
        const onlyText = {"text": text}
        return onlyText;
    }
}

// ユーザーデータを検証して処理する
function processUserData(userData) {
    // JSONとしての検証
    try {
        if (typeof userData === "string") {
        userData = JSON.parse(userData);
        }
    } catch (e) {
        return { valid: false, error: "Invalid JSON format" };
    }
    
    // 基本構造の検証
    if (!userData.text || !Array.isArray(userData.events)) {
        return {
            valid: true,
            data: {
                text: String(userData.text),
                events: []
            }
        };
    }

    let id = "";
    try {
        if (userData.id){
            if (userData.id.indexOf(" ") === -1){
                id = userData.id;
            }
        }
    } catch (e) {
        id = "";
    }
    
    // 各マークの検証
    const validatedevents = [];
    for (const event of userData.events) {
        // 必須フィールドのチェック
        if (typeof event.index !== "number" || !event.type) {
            continue; // 無効なマークはスキップ
        }
        
        // typeのホワイトリストチェック
        if (!ALLOWED_TYPES.includes(event.type)) {
            continue; // 許可されていないtypeはスキップ
        }
        
        // conditionsの検証
        if (Array.isArray(event.conditions)) {
            const validConditions = event.conditions.filter(cond => 
                typeof cond === "object" && cond.comp && typeof cond.comp === "string"
        );
            event.conditions = validConditions;
        } else {
            event.conditions = [];
        }
        
        // repeatの検証
        if (event.repeat !== "yes" && event.repeat !== "no") {
            event.repeat = "no"; // デフォルト値
        }
        
        validatedevents.push(event);
    }
    
    return {
        valid: true,
        data: {
            text: String(userData.text),
            events: validatedevents
        }
    };
}


// ファイル読み込み関数をPromiseを返すように変更
function initialDicload(filePath) {
    const i_dict = {};
    return fetch(filePath)
        .then(response => response.text())
        .then(text => {
        // テキストを処理してデータ構造に変換
            const lines = text.split('\n');
        
            // 行ごとに処理
            lines.forEach(line => {
                if (!line.trim()) return;
                const [key, value] = line.split('=');
                if (key && value) {
                    i_dict[key.trim()] = value.trim();
                }
            });                         
//                    console.log(i_dict);
            return i_dict; // 処理したデータを返す
        })
        .catch(error => console.error('ファイル読み込みエラー:', error));
}

// 辞書初期化関数
async function initDictionaries() {
    try {
        // 複数のファイルを並行して読み込み、全ての完了を待つ
        const [kanjiDict, kanaDict, tutorialsDict, kanjiProblem, kanaProblem, tutorialProblem] = await Promise.all([
            initialDicload("./dictionary-local.txt"),
            initialDicload("./dictionary-kana.txt"),
            initialDicload("./tutorial-dic.txt"),
            initialProbelmLoad("./names.txt"),
            initialProbelmLoad("./kana.txt"),
            initialProbelmLoad("./tutorial.txt")

        ]);

        // 読み込んだデータを格納

        dictionaries.kanji = kanjiDict;
        dictionaries.katakana = kanaDict;
        dictionaries.tutorial = tutorialsDict;
        dictionary = dictionaries[currentDictionary];

        targetData["names-kanji"] = kanjiProblem;
        targetData["names-katakana"] = kanaProblem;
        targetData["tutorial"] = tutorialProblem;
        console.log("全ての辞書の読み込みが完了しました");

    } catch (error) {
        console.error("辞書の読み込み中にエラーが発生しました:", error);
        throw error; // エラーを呼び出し元に伝播
    }
}        

// 辞書タイプの切り替え
function switchDictionary(type) {
    currentDictionary = type;

    infoForDataset[currentDataSet].dic = type

    dictionary = dictionaries[type];
    dictionaryTypeSelect.value = type;
    clearBuffer();
    updateDisplay();
    showNextTarget();
}

// データセットの切り替え
function switchDataSet(dataSet) {
    currentDataSet = dataSet;
    currentTargetIndex = infoForDataset[dataSet].probIndex;
    completedChars = [];
    
    // データセットに応じて辞書を切り替え
    dictlabel = infoForDataset[dataSet].dic
    switchDictionary(dictlabel)

    // タブのアクティブ状態を更新
    tabs.forEach(tab => {
        if (tab.dataset.target === dataSet) {
            tab.classList.add('active');
        } else {
            tab.classList.remove('active');
        }
    });
    
    if (dataSet === "tutorial"){
        dictionaryTypeSelect.disabled = true;
        console.log("ok");
    } else {
        dictionaryTypeSelect.disabled = false;
    }
    showNextTarget();
    checkEvent(currentTarget.text);    
}

// 動的計画法を使用して入力対象テキストからすべての可能な読みパターンを生成する関数
function generateReading(text) {

    const cleanText = text.replace(/\s+/g, '');
    const n = cleanText.length;
    
    // dp[i] = テキストの位置iまでの可能なすべての区切り方
    const dp = new Array(n + 1).fill().map(() => []);
    dp[0] = [[]]; // 空テキストの場合は空のパスのみ
    
    for (let i = 0; i < n; i++) {
        if (dp[i].length === 0) continue; // この位置までの区切り方がない場合はスキップ
        
        const remainingText = cleanText.substring(i);
        
        // 可能なすべてのマッチを探す
        for (const [key, value] of Object.entries(dictionary)) {
            if (remainingText.startsWith(value)) {
                const endIndex = i + value.length;
                const newItem = {
                    reading: key,
                    value: value,
                    startIndex: i,
                    endIndex: endIndex
                };
                
                // 既存のすべてのパスにこの新しいアイテムを追加
                for (const path of dp[i]) {
                    dp[endIndex].push([...path, newItem]);
                }
            }
        }
        
        // マッチがない場合は1文字進める (通常は辞書に単漢字が登録されているため起きないはず)
        if (dp[i + 1].length === 0 && i < n) {
            const char = cleanText.charAt(i);
            const newItem = {
                reading: char,
                value: char,
                startIndex: i,
                endIndex: i + 1
            };
            
            for (const path of dp[i]) {
                dp[i + 1].push([...path, newItem]);
            }
        }
    }
    
    // 最長マッチを優先して選択 (区切り数が最小のもの)
    let bestPattern = null;
    let bestScore = Infinity;
    let bestIndex = Infinity;
    
    for (const pattern of dp[n]) {
        const score = pattern.length; // 区切り数
        const firstThreeCharIndex = pattern.findIndex(item => item.reading.length === 3);
        
        if (pattern.length > 0) {
            if (score < bestScore) {
                bestPattern = pattern;
                bestScore = score;
                bestIndex = firstThreeCharIndex
            } else if (firstThreeCharIndex >= 0 && score === bestScore) {
                if (firstThreeCharIndex < bestIndex) {
                    bestPattern = pattern;
                    bestScore = score;
                    bestIndex = firstThreeCharIndex
                }
            }
        }
    }
    
    // 最長マッチを主要な読みとして、他のパターンを代替として保存
    const readings = bestPattern.map((item) => {
        return {
            reading: item.reading,
            value: item.value,
            completed: false,
            startIndex: item.startIndex,
            endIndex: item.endIndex
        };
    });
    
    // 代替パターンを追加
    readings.alternatives = dp[n].filter(pattern => pattern !== bestPattern);

    return readings;
}

// 読み単位を解析して表示用データを作成
function analyzeTargetReadings() {
    if (!currentTarget) return;
    
    currentTargetReadings = generateReading(currentTarget.text);
    updateTargetDisplay();
}

// 入力対象の表示を更新（色分け含む）
function updateTargetDisplay() {
    if (!currentTarget || !currentTargetReadings.length) return;
    
    // 漢字テキスト（色分け）
    let leadingSpaces = currentTarget.text.match(/^[\u3000]+/)?.[0] || '';
    let textHtml = '';
    let displayText = '';

    if (leadingSpaces) {
        textHtml = `<span>${leadingSpaces}</span>`;
        displayText = leadingSpaces;
    }

    for (let i = 0; i < currentTargetReadings.length; i++) {
        const item = currentTargetReadings[i];
        if (completedReadings.includes(i)) {
            textHtml += `<span style="color: #4CAF50;">${item.value}</span>`;
            displayText += item.value;
        } else {
            textHtml += `<span>${item.value}</span>`;
            displayText += item.value;
        }
        leadingSpaces = ''
        // スペースを保持
        if (i < currentTargetReadings.length - 1 && 
            (currentTarget.text.indexOf(' ') !== -1) && 
            (displayText.length === currentTarget.text.indexOf(' '))) {
            textHtml += ' ';
        }
    }
    
    // 読みテキスト（色分け）
    let readingHtml = '';
    for (let i = 0; i < currentTargetReadings.length; i++) {
        const item = currentTargetReadings[i];
        if (completedReadings.includes(i)) {
            readingHtml += `<span style="color: #4CAF50;">${item.reading}</span>`;
        } else {
            readingHtml += `<span>${item.reading}</span>`;
        }
        if (i < currentTargetReadings.length - 1) {
            readingHtml += ' ';
        }
    }
    
    targetTextElement.innerHTML = textHtml;
    targetReadingElement.innerHTML = readingHtml;
}

// 次の入力対象を表示
function showNextTarget() {
    const targets = targetData[currentDataSet];
    if (targets.length === 0) return;
    
    currentTarget = targets[currentTargetIndex];
    targetTextElement.textContent = currentTarget.text;
    
    // 読みを解析して表示を更新
//            analyzeTargetReadings();
    
    // 入力済み読みをリセット
    completedReadings = [];
    checkingIndex = 0;
    // 現在の入力対象の読み単位を解析
    analyzeTargetReadings();
    
    // 入力欄をクリア
    inputField.value = '';
    clearBuffer();
    updateDisplay();
}

// 次の入力対象に進む
function goToNextTarget() {
    currentTargetIndex = (currentTargetIndex + 1) % targetData[currentDataSet].length;
    infoForDataset[currentDataSet].probIndex = currentTargetIndex
    showNextTarget();
    showMessage("第 " + (currentTargetIndex + 1) + " 問 (" + targetData[currentDataSet].length + " 問中)", 0);
    checkEvent(currentTarget.text)
}

// 入力表示の更新
function updateDisplay() {
    inputDisplay.textContent = `再変換:${reConAble} マッチ:${matchCount} | 前回:${lastFixKey} - 現在:${inputBuffer}`;
}

function messageDisplay(text) {
    messageArea.textContent = text;
}

// バッファのクリア
function clearBuffer() {
    inputBuffer = "";
    matchCount = 0;
    reConAble = 0;
}

// 入力欄のクリア
function clearInputField() {
    inputField.value = '';
    clearBuffer();
    updateDisplay();
}

// 入力バッファの内容を変換
function checkAndConvert() {
    if (inputBuffer.length === 1) {
        return;
    }
    
    const value = dictionary[inputBuffer];
    const key = inputBuffer;
    
    if (value) {

        var bslength;
        if (matchCount === 0){
            bslength = key.length;
        } else {
            bslength = key.length - lastFixKey.length + dictionary[lastFixKey].length;
        }
        
        // 変換前のテキストエリアの状態を保存
        const cursorPos = inputField.selectionStart;
        const textBefore = inputField.value.substring(0, cursorPos - bslength);                
        const textAfter = inputField.value.substring(cursorPos);
        
        // 変換を適用
        inputField.value = textBefore + value + textAfter;
        
        // カーソル位置の調整
        const newPosition = textBefore.length + value.length;
        inputField.setSelectionRange(newPosition, newPosition);
        
        // 入力対象の文字が入力されたかチェック
        checkCompletedChars(value);
        
        // バッファと変換履歴を更新
        reConAble = 0;
        if (matchCount > 0) {
            // 再マッチ時 (3 文字)
            inputBuffer = "";
            matchCount = 0;
            reConAble = 1;
        } else {
            // 初回マッチ (2 or 3 文字)
            matchCount += 1;
        }
        lastFixKey2 = lastFixKey;
        lastFixKey = key;
    } else {
        if (matchCount === 1) {
            // 3 文字のマッチなし、最後の 1 文字残してバッファをクリア
            inputBuffer = inputBuffer.charAt(inputBuffer.length - 1);
            matchCount = 0;
        }
    }
    updateDisplay();
}

// 入力された漢字が入力対象の順序に一致するかチェック
function checkCompletedChars(value) {
    if (!currentTarget || !currentTargetReadings.length) return;
    
    const cleanText = currentTarget.text.replace(/\s+/g, '');
    
    // 現在のインデックス位置を取得
    let currentIndex = checkingIndex;
    
    // 入力値のマッチ位置を検索
    const indices = [];
    let index = cleanText.indexOf(value);
        while (index !== -1) {
        indices.push(index);
        index = cleanText.indexOf(value, index + 1);
    }

    let matchPosition = -1;
    for (const idx of indices) {
        if (idx <= checkingIndex && idx + value.length > checkingIndex) {
            matchPosition = idx;
        }
    }
    
    // マッチが見つかり、かつマッチ位置が現在のインデックス以前の場合
    if (matchPosition !== -1 && matchPosition <= currentIndex) {
        // 入力値の末尾位置を計算
        checkingIndex = matchPosition + value.length;
        
        completedReadings = [];
        // マッチした部分をカバーする読み単位を特定
        for (let i = 0; i < currentTargetReadings.length; i++) {
            const reading = currentTargetReadings[i];
            if (reading.endIndex > checkingIndex) {
                break;
            }
            completedReadings.push(i);
        }

        checkEvent(cleanText);
        
        // 表示を更新
        updateTargetDisplay();
        
        // すべての読みが完了したかチェック
        if (completedReadings.length === currentTargetReadings.length) {
            showMessage("入力完了！ 次の問題に進みます。");
            setTimeout(() => {
                goToNextTarget();
            }, 0);
        }
    }
}

function checkEvent(target) {
    try {
        if (!currentTarget || currentTarget.events.length == 0) return;
    } catch(err) {
        console.log(err);
        return
    }

    // 特定の漢字が入力されたかチェック
    for (const typingEvent of currentTarget.events) {
        if(checkingIndex === typingEvent.index){
            const completedCondition = target.substr(0, typingEvent.index)
            if (completedCondition === typingEvent.condition){
                console.log("event");
                showMessage(typingEvent.content, typingEvent.timer);

            }
        }
    }
    return false;
}

// バックスペース処理
function backspaceBuffer() {
    if (inputBuffer === lastFixKey) {  // 変換直後
        clearBuffer();
    } else if (inputBuffer === "") {
        clearBuffer();
    } else {
        inputBuffer = inputBuffer.substring(0, inputBuffer.length - 1);
        if (inputBuffer === "") {
            if (reConAble === 1) {
                clearBuffer();
                reConAble = 1;
            } else {
                clearBuffer();
            }
        }
    }
    updateDisplay();
}

// 再変換処理
function reConvert() {
    if (reConAble === 1) {
        const followPart = inputBuffer;
        const redoPart = lastFixKey.substring(lastFixKey2.length);
        const lastFixValue = dictionary[lastFixKey];
        const lastFixValue2 = dictionary[lastFixKey2];
        
        // 現在のカーソル位置を取得
        const cursorPos = inputField.selectionStart;
        const textBefore = inputField.value.substring(0, cursorPos - lastFixValue.length - followPart.length);
        const textAfter = inputField.value.substring(cursorPos);
        
        // 変換前の状態に戻す
        inputField.value = textBefore + lastFixValue2 + redoPart + followPart + textAfter;
        
        // カーソル位置の調整
        const newPosition = textBefore.length + lastFixValue2.length + redoPart.length + followPart.length;
        inputField.setSelectionRange(newPosition, newPosition);

        // 変換履歴を一時保存
        const lastFixKeyBackup = lastFixKey;
        const lastFixKey2Backup = lastFixKey2;
        clearBuffer();
        
        // 入力バッファを更新して変換
        inputBuffer = redoPart + followPart;
        checkAndConvert();
        
        // 変換履歴を更新
        if (lastFixKey === lastFixKeyBackup) {
            lastFixKey = lastFixKey2Backup; // 後続の変換なし
        }
        lastFixKey2 = lastFixKey2Backup;
        reConAble = 0;
        
        updateDisplay();
    }
}

// システムの一時停止/再開
function toggleSystem() {
    isActive = !isActive;
    if (!isActive) {
        clearBuffer();
        inputDisplay.textContent = "システム停止中";
        inputDisplay.style.backgroundColor = "#FF9900";
        toggleButton.classList.add('suspended');
        showMessage("システム停止中", 0);

    } else {
        inputDisplay.style.backgroundColor = "#f5f5f5";
        toggleButton.classList.remove('suspended');
        showMessage("システム再開します");
        updateDisplay();
    }
}

function parseKeyValueFormat(str) {
    const pattern = /^([a-zA-Z0-9]{2,3})=([\u3000-\u9FFF]+)$/;
    
    const match = str.match(pattern);
    if (!match) {
      return null; // フォーマット不一致
    }
    
    return {
      key: match[1],   // 最初のキャプチャグループ（キー部分）
      value: match[2]  // 2番目のキャプチャグループ（値部分）
    };
}
 
// 外部辞書ファイルを読み込む
function loadExternalDictionary() {
    const file = dictionaryFileInput.files[0];
    if (!file) {
        alert("ファイルを選択してください。");
        return;
    }

    const reader = new FileReader();
    reader.onload = function(e) {
        const content = e.target.result;
        const customDictionary = {};

        // 行ごとに処理
        content.split('\n').forEach(line => {
            if (!line.trim()) return;
            const nline = line.replace(/\r/g, '');
            
            const pair = parseKeyValueFormat(nline);
            if (pair) {
                customDictionary[pair.key] = pair.value;
              } else {
                console.log('無効なフォーマットです');
              }
        });
        
        // カスタム辞書名を取得
        let customName = dictionaryNameInput.value.trim();

        // 既存の辞書をマージまたは置き換え
        const dicName = "ユーザー" + String(Object.keys(dictionaries).length - 1);
        if (Object.keys(customDictionary).length > 0) {

            if (!customName) {
                const options = dictionaryTypeSelect.querySelectorAll("#dictionaryType option")
                const values = Array.from(options)
                    .map(option => option.textContent)
                    .filter(value => value.includes("ユーザー"));

                customName = "ユーザー辞書" + String(values.length + 1);
            }         

            const dictKey = "custom-dict-" + Date.now();
            dictionaries[dictKey] = customDictionary;
            dictionary = dictionaries[dictKey];

            // セレクタに新しい辞書を追加
            dictionaryTypeSelect.add(new Option(customName + " (" +file.name+ ")", dictKey));
            dictionaryTypeSelect.value = dictKey;

            alert(`${Object.keys(customDictionary).length}件の辞書エントリを読み込みました。`);
            infoForDataset[currentDataSet].dic = dictKey
            analyzeTargetReadings()
            updateDisplay();
        } else {
            alert("有効な辞書エントリが見つかりませんでした。");
        }
    };
    reader.readAsText(file);
}

function userDataFormat(str) {
    const pattern = /^([\u3000-\u9FFF]+)$/;
    
    const match = str.match(pattern);
    if (!match) {
      return null; // フォーマット不一致
    }
    
    return {
      value: match[1]  // 2番目のキャプチャグループ（値部分）
    };
}

// 外部問題ファイルの 1 行をパース
function parseUserDataFormat(str) {
    const pattern = /^([\u3000-\u9FFF])+[ ]?([\u3000-\u9FFF]+)$/;
    
    const match = str.match(pattern);
    if (!match) {
      return null; // フォーマット不一致
    }
    
    return {
      text: match[0],   // 最初のキャプチャグループ（キー部分）
      events: []
    };
}

// 外部問題ファイルを読み込む
function loadExternalProblems() {
    const file = problemsFileInput.files[0];
    if (!file) {
        alert("ファイルを選択してください。");
        return;
    }

    const reader = new FileReader();
    reader.onload = function(e) {
        const content = e.target.result;
        const customProblems = [];

        
        // 行ごとに処理
        content.split('\n').forEach(line => {
            if (!line.trim()) return;
            const nline = line.replace(/\r/g, '');
            
            const value = parseUserDataFormat(nline);
            if (value) {
                customProblems.push(value);
              } else {
                console.log('無効なフォーマットです');
              }
        });
        
        
        // 問題が読み込めた場合
        if (customProblems.length > 0) {
            // カスタム問題セット名を取得
            let customName = problemsNameInput.value.trim();
            
            // 新しいデータセット名を生成
            const datasetKey = `custom-${Date.now()}`;
            infoForDataset[datasetKey] = {};
                        
            // 既存のデータセットに追加
            targetData[datasetKey] = customProblems;
            infoForDataset[datasetKey].probIndex = 0;

            // 表示名の設定
            if (!customName) {
                customName = file.name || `問題セット ${Object.keys(targetData).length}`;
            }
            
            // 新しいタブを追加
            addDatasetTab(datasetKey, customName);
            
            alert(`${customProblems.length}件の問題を読み込みました。`);
            
            // 新しいデータセットに切り替え
            switchDataSet(datasetKey);
            
            // 名前入力欄をクリア
            problemsNameInput.value = '';
        } else {
            alert("有効な問題が見つかりませんでした。");
        }
    };
    reader.readAsText(file);
}



// 新しいデータセットのタブを追加する関数
function addDatasetTab(datasetName, displayName) {
    const tabGroup = document.querySelector('.tab-group');
    const newTab = document.createElement('div');
    newTab.className = 'tab';
    newTab.dataset.target = datasetName;
    newTab.textContent = displayName || `問題セット ${datasetName.split('-')[1]}`;
    
    // データセット用の辞書タイプを設定
    infoForDataset[datasetName].dic = currentDictionary;
    
    // タブクリックイベントを追加
    newTab.addEventListener('click', function() {
        switchDataSet(this.dataset.target);
    });
    
    tabGroup.appendChild(newTab);
    tabs = document.querySelectorAll('.tab');
}

// 設定パネルの表示/非表示を切り替える
function toggleSettingsPanel() {
    const settingsContainer = document.querySelector('.settings-container');
    const toggleIcon = document.querySelector('.toggle-icon');
    
    settingsContainer.classList.toggle('visible');
    
    if (settingsContainer.classList.contains('visible')) {
        toggleIcon.textContent = '▲';
    } else {
        toggleIcon.textContent = '▼';
    }
}

// キー入力イベント
inputField.addEventListener('keydown', function(e) {
    if (!isActive) {
        // システム停止中は特殊キーのみ処理
        if ((e.ctrlKey && e.key === 'q') || (e.altKey && e.key === 'F12')) {
            toggleSystem();
            e.preventDefault();
        }
        return;
    }
    
    // 特殊キー処理
    if (e.key === 'Backspace') {
        isBackspacePressed = true;
        backspaceBuffer();
        return;
    } else if (e.ctrlKey && (e.key === 'h')) {
        isBackspacePressed = true;
        backspaceBuffer();
        e.preventDefault();
        return;
    } else if (e.ctrlKey && (e.key === 'k' || e.key === 'l')) {
        reConvert();
        e.preventDefault();
        return;
    } else if ((e.ctrlKey && e.key === 'q') || (e.altKey && e.key === 'F12')) {
        toggleSystem();
        e.preventDefault();
        return;
    } else if (e.key === 'Escape') {
        clearInputField();
        e.preventDefault();
        return;
    } else if (e.key === 'F2') {
        goToNextTarget();
        showMessage("次の問題に進みます。" + (currentTargetIndex + 1) + "/" + targetData[currentDataSet].length);
        checkEvent(currentTarget.text);    
        e.preventDefault();

        return;
    } else if (e.key === 'Enter' || e.key === ' ' || e.key === 'Tab' ||
                e.key === 'ArrowLeft' || e.key === 'ArrowRight' || e.key === 'ArrowUp' || e.key === 'ArrowDown') {
        clearBuffer();
        updateDisplay();
        return;
    }
    
    // 通常の入力処理は input イベントで行う
});

// タイマー付メッセージ表示
function showMessage(message, duration = 2000) {
    // 既存のタイマーがあればクリアする
    if (currentMessageTimer !== null) {
        clearTimeout(currentMessageTimer);
        currentMessageTimer = null;
    }
    
    // メッセージを表示
    messageDisplay(message);
    
    // durationが指定されている場合のみタイマーをセット
    if (duration > 0) {
        currentMessageTimer = setTimeout(() => {
            messageDisplay("");
            currentMessageTimer = null;
        }, duration);
    }
    
    return currentMessageTimer;
}

// バックスペースのキーアップでフラグをリセット
inputField.addEventListener('keyup', function(e) {
    if (e.key === 'Backspace' || (e.ctrlKey && e.key === 'h')) {
        setTimeout(() => {
            isBackspacePressed = false;
        }, 10);
    }
});

// テキスト入力イベント
inputField.addEventListener('input', function(e) {
    if (!isActive) return;
    
    // バックスペースキーが押されている場合は処理しない
    if (isBackspacePressed) {
        return;
    }
    
    // 最後に入力された文字を取得
    const lastChar = inputField.value.charAt(inputField.selectionStart - 1);
    
    // 入力文字が有効な場合のみバッファに追加
    if (lastChar && /[a-z0-9.\-@]/.test(lastChar)) {
        inputBuffer += lastChar;
        updateDisplay();
        checkAndConvert();
    }
});

// 更新ボタンのクリックイベント
nextTargetButton.addEventListener('click', goToNextTarget);

// クリアボタンのクリックイベント
clearInputButton.addEventListener('click', clearInputField);

// トグルボタンのクリックイベント
toggleButton.addEventListener('click', toggleSystem);

// 辞書読み込みボタンのクリックイベント
loadDictionaryButton.addEventListener('click', loadExternalDictionary);

// 問題読み込みボタンのクリックイベント
loadProblemsButton.addEventListener('click', loadExternalProblems);

// 辞書タイプ変更イベント
dictionaryTypeSelect.addEventListener('change', function() {
    switchDictionary(this.value);
});

// タブ切り替えイベント
tabs.forEach(tab => {
    tab.addEventListener('click', function() {
        showMessage("")
        switchDataSet(this.dataset.target);
    });
});

// 初期化を実行する関数
async function initialize() {
    await initDictionaries();
    showNextTarget();
    checkEvent(currentTarget.text)
    updateDisplay();
}

// 設定トグルボタンのクリックイベント
document.querySelector('.settings-header').addEventListener('click', toggleSettingsPanel);

// 初期化
initialize().catch(error => {
    console.error("初期化中にエラーが発生しました:", error);
});
