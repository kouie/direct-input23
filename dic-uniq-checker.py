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

def main():
	ignore_character = 'vq7px'
	dic = 'dictionary-local.txt'
	dict2, dict3 = read_dictionary(dic)
	
	allow_suffix = list(ignore_character)
	key3 = dict3.keys()
	key2 = dict2.keys()

	allow_list = []
	numbered_list = []
	target_list = []

	all_counter = 0
	counter_modified = 0
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
					allow_list.extend(temporary)
					subt = 'a--------------------> ' + key2 + ' ' + k3 + ' ' + str(counter)
					allow_list.append(subt)
				elif re.match('[0-68-9]',k3[2]):
					numbered_list.extend(temporary)
					subt = 'n--------------------> ' + key2 + ' ' + k3 + ' ' + str(counter)
					numbered_list.append(subt)
				else:
					counter_modified +=1
					target_list.extend(temporary)
					subt = '---------------------> ' + key2 + ' ' + k3 + ' ' + str(counter)
					target_list.append(subt)

				all_counter += 1

	o0 = '\n'.join(target_list) + '\n'
	o1 = '\n'.join(allow_list) + '\n'
	o2 = '\n'.join(numbered_list) + '\n'
	to = '\ntotal: ' + str(all_counter) + ' target: ' + str(counter_modified)

	with open('uniq-check-results.txt', 'w', encoding='utf-8-sig') as f:
		f.write(o0)
		f.write(o1)
		f.write(o2)
		f.write(to)

	print('total:', all_counter, counter_modified)
	return


if __name__ == "__main__":
	main()
