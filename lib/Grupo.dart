import 'Produto.dart';

class Grupo {
  String nome;
  List<Produto> produtos;

  Grupo({required this.nome, required this.produtos});

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'produtos': produtos.map((produto) => produto.toJson()).toList(),
    };
  }

  factory Grupo.fromJson(Map<String, dynamic> json) {
    return Grupo(
      nome: json['nome'],
      produtos: (json['produtos'] as List<dynamic>).map((item) => Produto.fromJson(item)).toList(),
    );
  }
}