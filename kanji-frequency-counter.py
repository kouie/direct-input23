import re
from collections import Counter
from datetime import datetime

def process_input_file(input_file):
    kanji_list = ""
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        for i in range(0, len(lines), 2):
            if i+1 < len(lines) and not lines[i+1].startswith('rc'):
#                kanji_list.extend(list(lines[i+1].strip()))
                kanji_list += lines[i+1]
    return kanji_list

def count_kanji(kanji_list):
    return Counter(kanji_list.split())

def write_priority_file(counter, output_file):
    with open(output_file, 'w', encoding='utf-8') as f:
        for kanji, _ in counter.most_common():
            f.write(f"{kanji}\n")

def write_log_file(counter, log_file):
    with open(log_file, 'w', encoding='utf-8') as f:
        f.write(f"集計日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"総文字数: {sum(counter.values())}\n")
        f.write(f"異なる漢字数: {len(counter)}\n\n")
        f.write("漢字,出現回数,割合\n")
        total = sum(counter.values())
        for kanji, count in counter.most_common():
            percentage = (count / total) * 100
            f.write(f"{kanji},{count},{percentage:.2f}%\n")

def main():
    input_file = 'convert_history.txt'  # 入力ファイル名
    priority_file = 'kanji_priority.txt'  # 優先順位ファイル名
    log_file = 'kanji_frequency_log.txt'  # ログファイル名

    kanji_list = process_input_file(input_file)
    kanji_counter = count_kanji(kanji_list)

#    write_priority_file(kanji_counter, priority_file)
    write_log_file(kanji_counter, log_file)

#    print(f"処理が完了しました。結果は {priority_file} と {log_file} に保存されました。")
    print(f"処理が完了しました。結果は {log_file} に保存されました。")

if __name__ == "__main__":
    main()
