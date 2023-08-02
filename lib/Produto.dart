class Produto {
  String nome;

  Produto({required this.nome});

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
    };
  }

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      nome: json['nome'],
    );
  }
}