import sys
import os
import re
import argparse

def read_dictionary(file_path):
	dict2 = {}		# 2 文字
	dict3 = {}		# 3 文字
	with open(file_path, 'r', encoding='utf-8-sig') as f:
		for line in f:
			if '=' not in line:
				continue
			reading, kanji = line.strip().split('=')
			if len(reading) == 2:
				dict2[reading] = kanji
			else:
				dict3[reading] = kanji

	return dict2, dict3

def print_result(buf):
	for string in buf:
		print(string)

def main(dic_file: str, dtailed: int, ignore_chrs: str):
	dic = dic_file
	ignore_characters = ignore_chrs

	dict2, dict3 = read_dictionary(dic)
	
	allow_suffix = list(ignore_characters)
	key3 = dict3.keys()
	key2 = dict2.keys()

	allow_list = []
#	numbered_list = []
	target_list = []

	all_counter = 0
	counter_not = 0
#	counter_num = 0
	counter_alw = 0
	for key2 in key2:
		for k3 in key3:
			counter = 0
			match = ''
			temporary = []
			if key2 == k3[:2]:
				match = k3
				for k2 in dict2:
					if k3[2] == k2[0]:
						counter += 1
						out = key2 + ' ' + dict2[key2] + ' ' + k3 + ' ' + dict3[k3] + ' ' + k2 + ' ' + dict2[k2]
						temporary.append(out)

			if counter > 0:
				if k3[-1] in allow_suffix:
					counter_alw += 1
					allow_list.extend(temporary)
					subt = 'a--------------------> ' + key2 + ' ' + k3 + ' (' + str(counter) + ' 件)'
					allow_list.append(subt)
#				elif re.match('[0-68-9]',k3[2]):
#					counter_num +=1
#					numbered_list.extend(temporary)
#					subt = 'n--------------------> ' + key2 + ' ' + k3 + ' (' + str(counter) + ' 件)'
#					numbered_list.append(subt)
				else:
					counter_not +=1
					target_list.extend(temporary)
					subt = '---------------------> ' + key2 + ' ' + k3 + ' (' + str(counter) + ' 件)'
					target_list.append(subt)

				all_counter += 1

	o0 = '\n'.join(target_list) + '\n\n'
#	o1 = '\n'.join(numbered_list) + '\n\n'
	o2 = '\n'.join(allow_list) + '\n\n'
	to = '\ntotal: ' + str(all_counter) + ' target: ' + str(counter_not)

	mes = '辞書 ' + dic + ' には変換が一意に決まらない 3 文字のエントリが ' + str(all_counter) + ' 件あります。\n\n'
	
	if ignore_characters != '':
		mes += '内訳:\n'
		mes += '1. 次の 2. に該当しないもの (---): ' + str(counter_not) + ' 件\n'
		mes += '2. 読みの末尾が ' + ignore_characters + ' のいずれか (a--): ' + str(counter_alw) + ' 件\n\n'
#		mes += '2. 読みの末尾が数字 (n--): ' + str(counter_num) + ' 件\n'
		if detailed == 1:
			mes += '括弧内の記号は下記リストの集計行の先頭を表します (リストは 1. → 2. の順にまとめています)。\n\n'

	if detailed == 1:
		mes += 'リストの読み方\n'
		mes += '・ 以下のリストの各行は、変換が一意に決まらないケースの 1 つを読みと単語のセットで示しています。\n'
		mes += '・ 1 番目の読みと 3 番目の読みを続けて入力した場合、2 番目の (読みが 3 文字の) 単語に優先して変換されますので、3 番目の単語に変換したい場合は再変換操作が必要になります。\n'
		mes += '・ 「---」または「a--」で始まる行 (集計行) に表示されている件数は、1 番目の読みと 2 番目の読みのペアに対して変換が一意に決まらない 2 文字の読みの数です。'
		mes += '上の集計結果では、このペアを 1 件としてカウントしています。\n\n'

	with open('uniq-check-results.txt', 'w', encoding='utf-8-sig') as f:
		f.write(mes)
		f.write(o0)
	#	f.write(o1)
		f.write(o2)
		f.write(to)
	
	print('total:', all_counter, counter_not)
	return

def print_usage():
	print('Useage: python dic-uniq-checker.pyn <dictionary-name> [-d] [-i <ignore-characters>]')


if __name__ == "__main__":
	parser = argparse.ArgumentParser(
		add_help=True
	)
	parser.add_argument('dictionary_name', type=str)
	parser.add_argument('--c', help='ignore_chracters', type=str)
	parser.add_argument('--d', action='store_true')

	if len(sys.argv) > 1:
		dic_file = str(sys.argv[1])
		isfile = os.path.isfile(dic_file)
		if os.path.isfile(dic_file):
		
			try:
				if sys.argv[2] == '-d' or sys.argv[4] == '-d':
					detailed = 1
				else:
					detailed = 0
			except IndexError:
				detailed = 0

			try:
				if sys.argv[2] == '-i':
					ignore_chrs = sys.argv[3]
				elif sys.argv[3] == '-i':
					ignore_chrs = sys.argv[4]
			except IndexError:
				ignore_chrs = ''

			print(dic_file, detailed, ignore_chrs)
			main(dic_file, detailed, ignore_chrs)

		else:
			print('Err: Dictionary file not found.')
			print_usage()

	else:
		print_usage()

