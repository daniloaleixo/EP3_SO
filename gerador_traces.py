import sys
import os
import random
import time

TAM_MAX_PROCESSO = 0
n_processos = 10
n_acessos_memoria = 10
processos_gerados_por_segundo = 2
acessos_gerados_por_segundo = 2
longevidade_do_proc = 5
count = 0
tempo = 0
file_name = ''
total = 100
virtual = 1000
s = 5
p = 10

random.seed(time.time())



if len(sys.argv) < 6:
	print "Modo de uso\n\n"
	print "geradorArquivosTrace <nome do arquivo de trace> <total> <virtual> <s> <p>\n"
	print "-n\tnumero de processos\n"
	print "-N\tnumero de acessos de memoria por processo\n"
	print "-p\tprocessos gerados por segundo\n"
	print "-a\tacessos gerados por segundo\n"
	print "-l\tquanto tempo um processo pode durar no maximo\n"
	print "\n"
	exit(0)
	
file_name = sys.argv[1]
total = sys.argv[2]
virtual = sys.argv[3]
s = sys.argv[4]
p = sys.argv[5]
TAM_MAX_PROCESSO = (int(virtual) / (int(longevidade_do_proc) 
				* int(processos_gerados_por_segundo) * 2) / int(p) )

print "bla1"

# pega os argumentos de entrada
if len(sys.argv) > 6:
	tamanho = len(sys.argv)
	while(tamanho > 6):
		if sys.argv[tamanho - 2] == '-n':
			n_processos = sys.argv[tamanho - 1]
			tamanho = tamanho - 2
		if sys.argv[tamanho - 2] == '-N':
			n_acessos_memoria = sys.argv[tamanho - 1]
			tamanho = tamanho - 2
		if sys.argv[tamanho - 2] == '-p':
			processos_gerados_por_segundo = sys.argv[tamanho - 1]
			tamanho = tamanho - 2
		if sys.argv[tamanho - 2] == '-a':
			acessos_gerados_por_segundo = sys.argv[tamanho - 1]
			tamanho = tamanho - 2
		if sys.argv[tamanho - 2] == '-l':
			longevidade_do_proc = sys.argv[tamanho - 1]
			tamanho = tamanho - 2

print "bla2"

#gera o arquivo de trace
file = open(file_name, "w");
	# escreve a primeira linha
file.write(str(total) + ' ' + str(virtual) + ' ' + 
			str(s) + ' ' + str(p) + "\n")

print "bla3"

	# escreve as linhas de processos
for proc_i in range(0, int(n_processos)):
	tamanho_processo = random.randrange(1, int(TAM_MAX_PROCESSO)) * int(p)
	# print tamanho_processo
	tempo_termino = random.randrange(tempo + 1, int(int(tempo) + int(longevidade_do_proc)))

	file.write(str(tempo) + ' processo' + str(count) + ' ' 
				+ str(tempo_termino) + ' ' + str(tamanho_processo))


	for access_i in range(0, int(n_acessos_memoria)):
		onde_vou_acessar = random.randrange(1, tamanho_processo)
		quando_vou_acessar = random.randrange(tempo, tempo_termino)

		file.write(' ' + str(onde_vou_acessar) + ' ' + str(quando_vou_acessar))



	file.write('\n')
	tempo += 1

file.close()