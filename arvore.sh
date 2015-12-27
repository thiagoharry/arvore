#!/bin/bash

DIR_SCRIPT="/tmp/.arvore_dot/"

# O pacote graphviz é usado para gerar o desenho por meio do comando 'dot'
function testa_graphviz(){
    dot -V &> /dev/null
    if [ $? == 0 ]; then
	return 0;
    fi
    return 1;
}

# Identifica tipo de arquivo e deixa-o em formato especial de acordo com isso
function atributos_especiais(){
    if [[ -d $1 || ${diretorios:0:1} = "d" ]]; then
	echo "shape=box"
    elif [[ -x $1 || ${execucao:0:1} = "x" ]]; then
	echo "style=filled"
    else
	echo ""
    fi
}

# Dado um caminho para arquivo, declara um vértice na linguagem DOT para ele
function cria_vertice(){
    echo "\"$(limpa_string $1)\"[label=\"$(basename $1)\" $(atributos_especiais $1)];"
}

# Dado um caminho para arquivo, cria uma aresta na lingüagem DOT.
function cria_aresta(){
    echo "\"$(dirname $1)\"->\"$(limpa_string $1)\";"
}

# Recebe string e remove o último caractere se for um '/'
function limpa_string(){
    echo $1 | sed -e 's/\/$//'
}

#### MAIN ####
if ! testa_graphviz; then
    echo "For using this script, install graphviz package with:"
    echo "# apt-get install graphviz"
    exit 1
fi
if [ $# -ne 1 ]; then
    echo "You should pass exactly 1 argument for this script: the name"
    echo "of some installed package."
    exit 1
fi

arquivos=""     # Lista de todos os arquivos
diretorios=""   # Se ele não está instalado, quais são diretórios
execucao=""     # Se ele não está instalado, quais são executáveis
if [ -f "$1" ]; then
    arquivos=$(dpkg -c $1 2> /dev/null | cut -d "." -f 2- | tail -n +2)
    diretorios=$(dpkg -c $1 2> /dev/null | cut -c 1 | tail -n +2)
    execucao=$(dpkg -c $1 2> /dev/null | cut -c 4 | tail -n +2)
else
    arquivos=$(dpkg -L $1 2> /dev/null | tail -n +2)
    if [ -z "$arquivos" ]; then
	echo "Package ${1} not installed in the system."
	exit 1
    fi
fi
if [ $(echo $arquivos | wc -w) -gt 170 ]; then
    echo "Package ${1} install too many files. Trying to create an image"
    echo "could exaust your machine resources."
    exit 1
fi
vertices=""
arestas=""
arquivo_dot="/"
IFS=$'\n'
i=0
for linha in $arquivos; do
    vertices=${vertices}$(cria_vertice $linha)
    arestas=${arestas}$(cria_aresta $linha)
    diretorios=${diretorios:2}
    execucao=${execucao:2}
    i=$(($i+1))
done
if [ ! -e $DIR_SCRIPT ]; then
    mkdir $DIR_SCRIPT
fi
cd ${DIR_SCRIPT}
arquivo_fonte=${DIR_SCRIPT}/$$
echo "digraph arvore{" > $arquivo_fonte
echo "\"/\"[shape=box];" >> $arquivo_fonte
echo $vertices >> $arquivo_fonte
echo $arestas >> $arquivo_fonte
echo "}" >> $arquivo_fonte
dot -Tpng $arquivo_fonte -o $$.png

# Que visualizador de imagens usar?
eog $$.png 2> /dev/null || gimv $$.png 2> /dev/null ||
gwenview $$png 2> /dev/null || kuickshow $$.png 2> /dev/null ||
qiv $$.png 2> /dev/null || ristretto $$.png 2> /dev/null ||
feh $$.png 2> /dev/null || geeqie $$.png 2> /dev/null ||
gthumb $$.png 2> /dev/null || nomacs $$.png 2> /dev/null ||
gpicview $$.png 2> /dev/null || xee $$.png 2> /dev/null ||
firefox $$.png 2> /dev/null || display $$.png 2> /dev/null ||
gimp $$.png 2> /dev/null || chromium-browser $$.png 2> /dev/null ||
echo "No known image viewer found." && exit 1


rm $$.png
rm $arquivo_fonte
