import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item_pca.dart';

class ApiService {
  static String baseUrl = 'http://localhost:8000';
  static String? currentUserRole;
  static String? currentUsername;

  // Buscar todos os itens (com filtros opcionais)
  Future<Map<String, dynamic>> fetchItens({String? busca, String? pasta, String? laboratorio, String? categoriaItem, int? ano}) async {
    try {
      final queryParams = <String, String>{};
      if (busca != null && busca.isNotEmpty) {
        queryParams['busca'] = busca;
      }
      if (pasta != null && pasta.isNotEmpty) {
        queryParams['pasta'] = pasta;
      }
      if (laboratorio != null && laboratorio.isNotEmpty) {
        queryParams['laboratorio'] = laboratorio;
      }
      if (categoriaItem != null && categoriaItem.isNotEmpty) {
        queryParams['categoria_item'] = categoriaItem;
      }
      if (ano != null) {
        queryParams['ano'] = ano.toString();
      }

      final uri = Uri.parse('$baseUrl/api/pca').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['itens'] as List)
            .map((item) => ItemPCA.fromJson(item))
            .toList();
        
        return {
          'itens': list,
          'estatisticas': data['estatisticas'] ?? {},
        };
      }
    } catch (e) {
      print('Erro ao buscar itens do PCA: $e');
    }
    return {'itens': <ItemPCA>[], 'estatisticas': {}};
  }

  // Criar um novo item
  Future<bool> createItem(ItemPCA item) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pca'),
        headers: {
          'Content-Type': 'application/json',
          if (currentUserRole != null) 'X-User-Role': currentUserRole!,
          if (currentUsername != null) 'X-Username': currentUsername!,
        },
        body: jsonEncode(item.toJson()),
      );
      if (response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      print('Erro ao criar item do PCA: $e');
    }
    return false;
  }

  // Atualizar um item existente
  Future<bool> updateItem(int id, ItemPCA item) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/pca/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (currentUserRole != null) 'X-User-Role': currentUserRole!,
          if (currentUsername != null) 'X-Username': currentUsername!,
        },
        body: jsonEncode(item.toJson()),
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Erro ao atualizar item do PCA: $e');
    }
    return false;
  }

  // Excluir um item
  Future<bool> deleteItem(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/pca/$id'),
        headers: {
          if (currentUserRole != null) 'X-User-Role': currentUserRole!,
          if (currentUsername != null) 'X-Username': currentUsername!,
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Erro ao deletar item do PCA: $e');
    }
    return false;
  }

  // --- CONFIGURAÇÃO GLOBAL DE PRAZO (DEADLINE) ---
  Future<Map<String, dynamic>> fetchGlobalConfig() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/pca/config'));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('Erro ao buscar configuração global: $e');
    }
    return {'liberacao_fim': null, 'is_globally_released': false};
  }

  Future<bool> updateGlobalConfig(String? liberacaoFim) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pca/config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'liberacao_fim': liberacaoFim}),
      );
      if (response.statusCode == 200) return true;
    } catch (e) {
      print('Erro ao atualizar configuração global: $e');
    }
    return false;
  }

  // --- USUÁRIOS ---
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/pca/users'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('Erro ao buscar usuários: $e');
    }
    return [];
  }

  Future<bool> createUser(String username, String password, String name, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pca/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'name': name,
          'role': role,
        }),
      );
      if (response.statusCode == 201) return true;
    } catch (e) {
      print('Erro ao criar usuário: $e');
    }
    return false;
  }

  Future<bool> deleteUser(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/pca/users/$id'));
      if (response.statusCode == 200) return true;
    } catch (e) {
      print('Erro ao deletar usuário: $e');
    }
    return false;
  }

  Future<bool> updateUser(int id, String username, String name, String role, {bool editLocked = false, bool individualRelease = false, String? password}) async {
    try {
      final bodyMap = <String, dynamic>{
        'username': username,
        'name': name,
        'role': role,
        'edit_locked': editLocked,
        'individual_release': individualRelease,
      };
      if (password != null && password.trim().isNotEmpty) {
        bodyMap['password'] = password;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/pca/users/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );
      if (response.statusCode == 200) return true;
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
    }
    return false;
  }

  Future<bool> lockUserPlanning(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pca/users/$id/lock'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) return true;
    } catch (e) {
      print('Erro ao travar planejamento do usuário: $e');
    }
    return false;
  }

  // --- PARÂMETROS: LABORATÓRIOS ---
  Future<List<Map<String, dynamic>>> fetchLaboratoriosRaw() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/pca/laboratorios'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('Erro ao buscar laboratórios raw: $e');
    }
    return [];
  }

  Future<List<String>> fetchLaboratorios() async {
    final list = await fetchLaboratoriosRaw();
    return list.map((item) => item['nome'] as String).toList();
  }

  Future<bool> createLaboratorio(String nome) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pca/laboratorios'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nome': nome}),
      );
      if (response.statusCode == 201) return true;
    } catch (e) {
      print('Erro ao criar laboratório: $e');
    }
    return false;
  }

  Future<bool> deleteLaboratorio(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/pca/laboratorios/$id'));
      if (response.statusCode == 200) return true;
    } catch (e) {
      print('Erro ao deletar laboratório: $e');
    }
    return false;
  }

  // --- PARÂMETROS: CATEGORIAS ---
  Future<List<Map<String, dynamic>>> fetchCategoriasRaw() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/pca/categorias'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('Erro ao buscar categorias raw: $e');
    }
    return [];
  }

  Future<List<String>> fetchCategorias() async {
    final list = await fetchCategoriasRaw();
    return list.map((item) => item['nome'] as String).toList();
  }

  Future<bool> createCategoria(String nome) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pca/categorias'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nome': nome}),
      );
      if (response.statusCode == 201) return true;
    } catch (e) {
      print('Erro ao criar categoria: $e');
    }
    return false;
  }

  Future<bool> deleteCategoria(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/pca/categorias/$id'));
      if (response.statusCode == 200) return true;
    } catch (e) {
      print('Erro ao deletar categoria: $e');
    }
    return false;
  }

  // --- PARÂMETROS: TIPOS DE RECURSO ---
  Future<List<Map<String, dynamic>>> fetchTiposRecursoRaw() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/pca/tipos-recurso'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('Erro ao buscar tipos de recurso raw: $e');
    }
    return [];
  }

  Future<List<String>> fetchTiposRecurso() async {
    final list = await fetchTiposRecursoRaw();
    return list.map((item) => item['nome'] as String).toList();
  }

  Future<bool> createTipoRecurso(String nome) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pca/tipos-recurso'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nome': nome}),
      );
      if (response.statusCode == 201) return true;
    } catch (e) {
      print('Erro ao criar tipo de recurso: $e');
    }
    return false;
  }

  Future<bool> deleteTipoRecurso(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/pca/tipos-recurso/$id'));
      if (response.statusCode == 200) return true;
    } catch (e) {
      print('Erro ao deletar tipo de recurso: $e');
    }
    return false;
  }

  // --- LOGS DE AUDITORIA ---
  Future<List<Map<String, dynamic>>> fetchLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/pca/logs'),
        headers: {
          if (currentUserRole != null) 'X-User-Role': currentUserRole!,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['logs'] ?? []);
      }
    } catch (e) {
      print('Erro ao buscar logs: $e');
    }
    return [];
  }

  Future<bool> clearLogs() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/pca/logs'),
        headers: {
          if (currentUserRole != null) 'X-User-Role': currentUserRole!,
        },
      );
      if (response.statusCode == 200) return true;
    } catch (e) {
      print('Erro ao limpar logs: $e');
    }
    return false;
  }
}
