import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'Carrinho.dart';
import 'Grupo.dart';
import 'Produto.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PEDIDOS FILIAL',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _TelaInicialState createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  List<Grupo> grupos = [];
  List<CarrinhoItem> carrinho = [];
  bool groupsLoaded = false;
  final TextEditingController _nomeProdutoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarGrupos();
  }

  @override
  void dispose() {
    salvarGrupos();
    _nomeProdutoController.dispose();
    super.dispose();
  }

  List<String> get gruposExistentes {
    return grupos.map((grupo) => grupo.nome).toList();
  }

  Future<void> carregarGrupos() async {
    final prefs = await SharedPreferences.getInstance();
    final gruposJson = prefs.getString('grupos');

    if (gruposJson != null) {
      setState(() {
        grupos = (json.decode(gruposJson) as List<dynamic>).map((json) =>
            Grupo.fromJson(json)).toList();
        groupsLoaded = true;
      });
    } else {
      String jsonString = await rootBundle.loadString(
          'assets/produtos_data.json');
      List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        grupos = jsonList.map((json) => Grupo.fromJson(json)).toList();
        groupsLoaded = true;
      });
    }
  }

  Future<void> salvarGrupos() async {
    final prefs = await SharedPreferences.getInstance();
    final gruposJson = jsonEncode(grupos);
    prefs.setString('grupos', gruposJson);
  }

  void adicionarProduto(Produto produto, int quantidade) {
    final itemExistente = carrinho.firstWhere(
          (item) => item.produto == produto,
      orElse: () {
        final novoItem = CarrinhoItem(produto: produto, quantidade: 0);
        carrinho.add(novoItem);
        return novoItem;
      },
    );

    itemExistente.quantidade += quantidade;

    if (itemExistente.quantidade <= 0) {
      carrinho.remove(itemExistente);
    }

    salvarGrupos();
  }

  Future<void> mostrarDialogoQuantidade(Produto produto) async {
    int quantidade = 0;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione a quantidade'),
          content: TextField(
            onChanged: (value) {
              quantidade = int.tryParse(value) ?? 0;
            },
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Quantidade'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                adicionarProduto(produto, quantidade);
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }


  void removerProduto(CarrinhoItem carrinhoItem) {
    setState(() {
      carrinho.removeWhere((item) => item.produto == carrinhoItem.produto);
      salvarGrupos();
    });
  }

  void mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void adicionarNovoProduto(String nomeProduto, String nomeGrupo) {
    final grupoExistente = grupos.firstWhere(
          (grupo) => grupo.nome == nomeGrupo,
      orElse: () {
        final novoGrupo = Grupo(nome: nomeGrupo, produtos: []);
        grupos.add(novoGrupo);
        return novoGrupo;
      },
    );

    final novoProduto = Produto(nome: nomeProduto);
    grupoExistente.produtos.add(novoProduto);

    salvarGrupos();
    setState(() {});
    mostrarMensagem('Produto adicionado com sucesso!');
  }

  void mostrarDialogoSelecionarGrupo(String nomeProduto) async {
    String? nomeGrupoSelecionado;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione o Grupo'),
          content: DropdownButtonFormField<String>(
            value: nomeGrupoSelecionado,
            onChanged: (String? newValue) {
              setState(() {
                nomeGrupoSelecionado = newValue;
              });
            },
            items: gruposExistentes.map((String grupo) {
              return DropdownMenuItem<String>(
                value: grupo,
                child: Text(grupo),
              );
            }).toList(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (nomeGrupoSelecionado != null) {
                  adicionarNovoProduto(nomeProduto, nomeGrupoSelecionado!);
                } else {
                  mostrarMensagem('Selecione um grupo válido.');
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  void mostrarDialogoAdicionarProduto() async {
    String? nomeProduto;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Novo Produto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomeProdutoController,
                onChanged: (value) {
                  nomeProduto = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (nomeProduto != null && nomeProduto!.isNotEmpty) {
                  Navigator.of(context).pop();
                  mostrarDialogoSelecionarGrupo(nomeProduto!);
                  _nomeProdutoController.clear();
                } else {
                  mostrarMensagem('Digite o nome do produto.');
                }
              },
              child: const Text('Próximo'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoConfirmarExclusao(bool isGrupo, String nome) async {
    bool confirmado = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Tem certeza que deseja excluir $nome?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(
                    false); // Define que não foi confirmado
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Define que foi confirmado
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmado) {
      // Se for confirmado, remover o grupo ou produto
      setState(() {
        if (isGrupo) {
          grupos.removeWhere((grupo) => grupo.nome == nome);
        } else {
          for (var grupo in grupos) {
            grupo.produtos.removeWhere((produto) => produto.nome == nome);
          }
        }
        salvarGrupos(); // Salvar as alterações após a exclusão
        mostrarMensagem('Exclusão realizada com sucesso!');
      });
    }
  }

  void criarArquivo() async {
    // Criação do conteúdo do documents PDF
    final pdf = pw.Document();
    final List<pw.Container> paragraphs = [];

    for (int i = 0; i < carrinho.length; i++) {
      CarrinhoItem item = carrinho[i];

      final paragraph = pw.Container(
        child: pw.Paragraph(
          style: pw.TextStyle(
            color: PdfColor.fromHex(
                (i % 4 == 0 || i % 4 == 3) ? '000000' : '575757'),
            fontSize: 10,
          ),
          text: '${item.produto.nome}: ${item.quantidade}',
        ),
        margin: const pw.EdgeInsets.only(bottom: 5),
      );

      paragraphs.add(paragraph);
    }

    // Function to generate a page with the provided content
    pw.Widget buildPage(List<pw.Container> leftColumn,
        List<pw.Container> rightColumn) {
      return pw.Container(
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: pw.Column(children: leftColumn,
                crossAxisAlignment: pw.CrossAxisAlignment.start)),
            pw.Expanded(child: pw.Column(children: rightColumn,
                crossAxisAlignment: pw.CrossAxisAlignment.end)),
          ],
        ),
      );
    }

    // Generate the multi-page PDF
    final List<pw.Widget> pages = [];
    List<pw.Container> currentPageLeftColumn = [];
    List<pw.Container> currentPageRightColumn = [];
    for (int i = 0; i < paragraphs.length; i++) {
      if (i % 2 == 0) {
        currentPageLeftColumn.add(paragraphs[i]);
      } else {
        currentPageRightColumn.add(paragraphs[i]);
      }

      if ((i + 1) % 46 == 0 || i == paragraphs.length - 1) {
        pages.add(buildPage(currentPageLeftColumn, currentPageRightColumn));
        currentPageLeftColumn = [];
        currentPageRightColumn = [];
      }
    }
    pdf.addPage(pw.MultiPage(build: (pw.Context context) => pages));

    // Caminho do arquivo temporário
    final directory = await getTemporaryDirectory();
    final now = DateTime.now();
    final formattedDate = '${now.day}-${now.month}-${now.year}';
    final path = '${directory.path}/$formattedDate.pdf';

    // Criação e escrita do arquivo
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    // Compartilhar o arquivo via WhatsApp
    Share.shareFiles(
        [path], text: 'Confira meu carrinho de compras', subject: 'Carrinho');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PEDIDOS FILIAL'),
      ),
      body: groupsLoaded
          ? SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: grupos.length,
          itemBuilder: (context, index) {
            final grupo = grupos[index];

            return Card(
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        grupo.nome,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _mostrarDialogoConfirmarExclusao(true, grupo.nome);
                      },
                    ),
                  ],
                ),
                children: grupo.produtos.map((produto) {
                  return ListTile(
                    title: Text(produto.nome),
                    onTap: () {
                      mostrarDialogoQuantidade(produto);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _mostrarDialogoConfirmarExclusao(false, produto.nome);
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      )
          : const Center(
        child: CircularProgressIndicator(),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16.0,
            right: 5.0,
            child: FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text('Carrinho'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: carrinho.length,
                              itemBuilder: (context, index) {
                                final carrinhoItem = carrinho[index];
                                return ListTile(
                                  title: Text(
                                      'Produto: ${carrinhoItem.produto.nome}'),
                                  subtitle: Text(
                                      'Quantidade: ${carrinhoItem.quantidade}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        removerProduto(carrinhoItem);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                criarArquivo();
                              },
                              child: const Text('Compartilhar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.shopping_cart),
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 80.0,
            child: FloatingActionButton(
              onPressed: () {
                mostrarDialogoAdicionarProduto();
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
