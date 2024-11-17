import sys
import re

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

def main( dic, ignore_characters):
#	ignore_characters = 'vq7px'
#	dic = 'dictionary-local.txt'
	dict2, dict3 = read_dictionary(dic)
	
	allow_suffix = list(ignore_characters)
	key3 = dict3.keys()
	key2 = dict2.keys()

	allow_list = []
	numbered_list = []
	target_list = []

	all_counter = 0
	counter_not = 0
	counter_num = 0
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
					subt = 'a--------------------> ' + key2 + ' ' + k3 + ' ' + str(counter)
					allow_list.append(subt)
				elif re.match('[0-68-9]',k3[2]):
					counter_num +=1
					numbered_list.extend(temporary)
					subt = 'n--------------------> ' + key2 + ' ' + k3 + ' ' + str(counter)
					numbered_list.append(subt)
				else:
					counter_not +=1
					target_list.extend(temporary)
					subt = '---------------------> ' + key2 + ' ' + k3 + ' ' + str(counter)
					target_list.append(subt)

				all_counter += 1

	o0 = '\n'.join(target_list) + '\n'
	o1 = '\n'.join(allow_list) + '\n'
	o2 = '\n'.join(numbered_list) + '\n'
	to = '\ntotal: ' + str(all_counter) + ' target: ' + str(counter_not)

	mes = '辞書 ' + dic + ' には変換が一意に決まらないエントリが ' + str(all_counter) + ' 件あります\n'
	mes += ' 末尾が ' + ignore_characters + ' のいずれか: ' + str(counter_alw) + ' 件 (集計行の先頭が a-)\n'
	mes += ' 末尾が数字: ' + str(counter_num) + ' 件 (集計行の先頭が 0-)\n'
	mes += ' いずれにも該当しないもの: ' + str(counter_not) + ' 件 (集計行の先頭が --)\n\n'

	with open('uniq-check-results.txt', 'w', encoding='utf-8-sig') as f:
		f.write(mes)
		f.write(o0)
		f.write(o1)
		f.write(o2)
		f.write(to)
	
	print('total:', all_counter, counter_not)
	return


if __name__ == "__main__":
	if len(sys.argv) == 3:
		main(sys.argv[1], sys.argv[2])
	else:
		print('Useage: python dic-uniq-checker.pyn dictionary-name ignore-characters')

