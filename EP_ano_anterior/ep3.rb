#!/usr/bin/env ruby

# TODO pensar no caso de carregar um disco que já foi criado em outra execução
# ou seja, fazer uma função inicializa FAT que lê o disco e iniciliza o FAT na memória

require './disk_operations.rb'

disk_operations = nil

loop do

  print "[ep3]: "
  # pega a linha de comando escrita pelo usuario
  option = gets.strip.split(" ")

  case option.shift
  when "sai" then break

  when "mount" # mount <arquivo>
    disk_path = option.first
    disk_operations = DiskOperations.new(disk_path)

  when "cp"     # cp <origem> <destino>
    origin_path = option.shift
    destination_path = option.shift
    disk_operations.cp(origin_path, destination_path)
    
  when "mkdir"  # mkdir <diretorio>
    path = option.shift
    disk_operations.mkdir(path)

  when "rmdir"  # rmdir <diretorio>
                # apaga o diretorio <diretorio>
    
  when "cat"    #cat <arquivo>
                # mostra o conteudo do arquivo <arquivo>

  when "touch"  # touch <arquivo>
    path = option.shift
    disk_operations.touch(path)

  when "rm"     # rm <arquivo>
    path = option.shift
    disk_operations.rm(path)    

  when "ls"     # ls <diretorio>
    path = option.shift
    disk_operations.ls(path)
  
  when "find"   # find <diretorio> <arquivo>
                # busca a partir de <diretorio> se ha algum arquivo com nome <arquivo>

  when "df"     # df
                # imprime na tela infos sobre o sistema de arquivos: quantidade de diretorios, quantidade de arquivos, 
                # espaco livre, espaco desperdicado

  when "umount" # umount
    disk_operations.umount
    
  else
    p "Comando inválido"
  end
end
