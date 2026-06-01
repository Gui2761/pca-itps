import os
from fastapi import FastAPI, HTTPException, status, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import psycopg2
import psycopg2.extras
from datetime import datetime

app = FastAPI(
    title="PCA API",
    description="Serviço REST de Gerenciamento do Plano de Contratações Anual (PCA) do ITPS",
    version="1.0.0"
)

# Permitir requisições CORS do app Flutter e do navegador
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- CONFIGURAÇÕES DO BANCO DE DADOS POSTGRES ---
PG_HOST = "172.23.6.109"
PG_PORT = 5432
PG_USER = "geinform"
PG_PASSWORD = "intr@bd109"
PG_DB = "bd_intranet"

def get_db_connection():
    conn = psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        user=PG_USER,
        password=PG_PASSWORD,
        database=PG_DB,
        cursor_factory=psycopg2.extras.RealDictCursor
    )
    return conn

def check_global_lock():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT liberacao_fim FROM pca.configuracoes WHERE id = 1")
        row = cursor.fetchone()
        if row:
            lib_fim = row['liberacao_fim']
            if lib_fim is None or datetime.now() > lib_fim:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="O período de edição do PCA não está ativo ou expirou. Contate o administrador."
                )
    finally:
        conn.close()

def check_user_lock(username: str):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT edit_locked FROM contratos.users WHERE username = %s", (username,))
        row = cursor.fetchone()
        if row and row['edit_locked']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Seu acesso de edição foi bloqueado após a finalização do planejamento."
            )
    finally:
        conn.close()

def init_db_tables():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Criar tabelas de parâmetros se não existirem
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS pca.laboratorios (
                id SERIAL PRIMARY KEY,
                nome VARCHAR(255) UNIQUE NOT NULL
            );
        """)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS pca.categorias (
                id SERIAL PRIMARY KEY,
                nome VARCHAR(255) UNIQUE NOT NULL
            );
        """)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS pca.tipos_recurso (
                id SERIAL PRIMARY KEY,
                nome VARCHAR(255) UNIQUE NOT NULL
            );
        """)
        conn.commit()

        # Popular com valores iniciais se estiverem vazias
        cursor.execute("SELECT COUNT(*) as count FROM pca.laboratorios")
        if cursor.fetchone()['count'] == 0:
            labs = [
                'Química de Águas', 'Inorgânica', 'Microbiologia', 'Solos', 
                'Bromatologia', 'Orgânica', 'Qualidade', 'Geconf', 'GEAAD / Insumos Gerais'
            ]
            for lab in labs:
                cursor.execute("INSERT INTO pca.laboratorios (nome) VALUES (%s) ON CONFLICT DO NOTHING", (lab,))
        
        cursor.execute("SELECT COUNT(*) as count FROM pca.categorias")
        if cursor.fetchone()['count'] == 0:
            cats = ['Laboratórios', 'PCA', 'GEAAD']
            for cat in cats:
                cursor.execute("INSERT INTO pca.categorias (nome) VALUES (%s) ON CONFLICT DO NOTHING", (cat,))

        cursor.execute("SELECT COUNT(*) as count FROM pca.tipos_recurso")
        if cursor.fetchone()['count'] == 0:
            recursos = ['Material de Consumo', 'Equipamento', 'Serviço']
            for rec in recursos:
                cursor.execute("INSERT INTO pca.tipos_recurso (nome) VALUES (%s) ON CONFLICT DO NOTHING", (rec,))
        
        # Autopopular usuários padrão dos setores e criar tabela de configurações
        try:
            cursor.execute("ALTER TABLE contratos.users ADD COLUMN IF NOT EXISTS edit_locked BOOLEAN DEFAULT FALSE;")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS pca.configuracoes (
                    id INT PRIMARY KEY,
                    liberacao_fim TIMESTAMP NULL
                );
            """)
            cursor.execute("INSERT INTO pca.configuracoes (id, liberacao_fim) VALUES (1, NULL) ON CONFLICT (id) DO NOTHING;")
            cursor.execute("SELECT username FROM contratos.users")
            existing_usernames = {row['username'] for row in cursor.fetchall()}
            
            setores_users = [
                {'username': 'quimica_aguas', 'name': 'Química de Águas', 'role': 'editor'},
                {'username': 'inorganica', 'name': 'Inorgânica', 'role': 'editor'},
                {'username': 'microbiologia', 'name': 'Microbiologia', 'role': 'editor'},
                {'username': 'solos', 'name': 'Solos', 'role': 'editor'},
                {'username': 'bromatologia', 'name': 'Bromatologia', 'role': 'editor'},
                {'username': 'organica', 'name': 'Orgânica', 'role': 'editor'},
                {'username': 'qualidade', 'name': 'Qualidade', 'role': 'editor'},
                {'username': 'geconf', 'name': 'Geconf', 'role': 'editor'},
                {'username': 'geaad', 'name': 'GEAAD / Insumos Gerais', 'role': 'editor'},
            ]
            
            for su in setores_users:
                if su['username'] not in existing_usernames:
                    cursor.execute(
                        "INSERT INTO contratos.users (username, password, name, role) VALUES (%s, %s, %s, %s)",
                        (su['username'], 'itps123', su['name'], su['role'])
                    )
        except Exception as u_err:
            print("Erro ao autopopular logins de setores:", u_err)

        conn.commit()
    except Exception as e:
        print("Erro ao inicializar tabelas:", e)
        conn.rollback()
    finally:
        conn.close()

init_db_tables()

# --- MODELOS PYDANTIC ---
class ItemPCAInput(BaseModel):
    origem_pasta: Optional[str] = "Manual"
    origem_arquivo: Optional[str] = "Inserção Direta"
    laboratorio: Optional[str] = "Geral"
    setor: Optional[str] = "Geral"
    categoria_item: Optional[str] = "Material de Consumo"
    tipo: Optional[str] = ""
    codigo: Optional[str] = ""
    item: str
    unidade: Optional[str] = ""
    quantidade: float
    valor_unitario: float
    ano: Optional[int] = 2027

# --- ENDPOINTS CRUD ---

@app.get("/api/pca")
def listar_itens(busca: Optional[str] = None, pasta: Optional[str] = None, laboratorio: Optional[str] = None, categoria_item: Optional[str] = None, ano: Optional[int] = None):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Query base
        query = "SELECT * FROM pca.itens WHERE 1=1"
        params = []
        
        if busca:
            query += " AND (item ILIKE %s OR tipo ILIKE %s OR codigo ILIKE %s OR setor ILIKE %s)"
            params.extend([f"%{busca}%", f"%{busca}%", f"%{busca}%", f"%{busca}%"])
            
        if pasta:
            query += " AND origem_pasta = %s"
            params.append(pasta)

        if laboratorio:
            query += " AND laboratorio = %s"
            params.append(laboratorio)

        if categoria_item:
            query += " AND categoria_item = %s"
            params.append(categoria_item)

        if ano:
            query += " AND ano = %s"
            params.append(ano)
            
        query += " ORDER BY id DESC"
        
        cursor.execute(query, params)
        itens = [dict(row) for row in cursor.fetchall()]
        
        # Calcular Estatísticas em Tempo Real (respeitando os filtros ativos)
        stats_query = "SELECT COUNT(*) as total_itens, SUM(valor_total) as valor_total_consolidado FROM pca.itens WHERE 1=1"
        stats_params = []
        
        if busca:
            stats_query += " AND (item ILIKE %s OR tipo ILIKE %s OR codigo ILIKE %s OR setor ILIKE %s)"
            stats_params.extend([f"%{busca}%", f"%{busca}%", f"%{busca}%", f"%{busca}%"])
        if pasta:
            stats_query += " AND origem_pasta = %s"
            stats_params.append(pasta)
        if laboratorio:
            stats_query += " AND laboratorio = %s"
            stats_params.append(laboratorio)
        if categoria_item:
            stats_query += " AND categoria_item = %s"
            stats_params.append(categoria_item)
        if ano:
            stats_query += " AND ano = %s"
            stats_params.append(ano)

        cursor.execute(stats_query, stats_params)
        stats = dict(cursor.fetchone())
        
        pasta_query = "SELECT origem_pasta, SUM(valor_total) as valor FROM pca.itens WHERE 1=1"
        pasta_params = []
        if ano:
            pasta_query += " AND ano = %s"
            pasta_params.append(ano)
        pasta_query += " GROUP BY origem_pasta"
        cursor.execute(pasta_query, pasta_params)
        por_pasta = [dict(r) for r in cursor.fetchall()]

        cat_query = "SELECT categoria_item, SUM(valor_total) as valor FROM pca.itens WHERE 1=1"
        cat_params = []
        if ano:
            cat_query += " AND ano = %s"
            cat_params.append(ano)
        cat_query += " GROUP BY categoria_item"
        cursor.execute(cat_query, cat_params)
        por_categoria = [dict(r) for r in cursor.fetchall()]

        # Soma por laboratório/setor um por um (para dashboard de visão geral)
        lab_query = "SELECT laboratorio, SUM(valor_total) as valor, COUNT(*) as count FROM pca.itens WHERE 1=1"
        lab_params = []
        if ano:
            lab_query += " AND ano = %s"
            lab_params.append(ano)
        lab_query += " GROUP BY laboratorio ORDER BY valor DESC"
        cursor.execute(lab_query, lab_params)
        por_laboratorio = [dict(r) for r in cursor.fetchall()]
        
        conn.close()
        return {
            "itens": itens,
            "estatisticas": {
                "total_itens": stats.get("total_itens", 0) or 0,
                "valor_total": stats.get("valor_total_consolidado", 0.0) or 0.0,
                "distribuicao_pasta": por_pasta,
                "distribuicao_categoria": por_categoria,
                "distribuicao_laboratorio": por_laboratorio
            }
        }
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro de Banco de Dados: {str(e)}")

@app.post("/api/pca", status_code=201)
def criar_item(input_data: ItemPCAInput, x_user_role: Optional[str] = Header(None), x_username: Optional[str] = Header(None)):
    if x_user_role != "admin":
        check_global_lock()
        if x_username:
            check_user_lock(x_username)

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Calcula valor total
        valor_total = input_data.quantidade * input_data.valor_unitario
        
        cursor.execute(
            """
            INSERT INTO pca.itens 
            (origem_pasta, origem_arquivo, laboratorio, setor, categoria_item, tipo, codigo, item, unidade, quantidade, valor_unitario, valor_total, data_sincronizacao, ano)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING id
            """,
            (
                input_data.origem_pasta,
                input_data.origem_arquivo,
                input_data.laboratorio,
                input_data.setor,
                input_data.categoria_item,
                input_data.tipo,
                input_data.codigo,
                input_data.item,
                input_data.unidade,
                input_data.quantidade,
                input_data.valor_unitario,
                valor_total,
                datetime.now(),
                input_data.ano or 2027
            )
        )
        new_id = cursor.fetchone()['id']
        conn.commit()
        conn.close()
        return {"id": new_id, "success": True, "message": "Item criado com sucesso!"}
    except Exception as e:
        conn.rollback()
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao inserir item: {str(e)}")

@app.put("/api/pca/{id}")
def atualizar_item(id: int, input_data: ItemPCAInput, x_user_role: Optional[str] = Header(None), x_username: Optional[str] = Header(None)):
    if x_user_role != "admin":
        check_global_lock()
        if x_username:
            check_user_lock(x_username)

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Calcula valor total
        valor_total = input_data.quantidade * input_data.valor_unitario
        
        cursor.execute(
            """
            UPDATE pca.itens 
            SET origem_pasta = %s, origem_arquivo = %s, laboratorio = %s, setor = %s, categoria_item = %s,
                tipo = %s, codigo = %s, item = %s, unidade = %s, quantidade = %s, valor_unitario = %s, valor_total = %s, ano = %s
            WHERE id = %s
            """,
            (
                input_data.origem_pasta,
                input_data.origem_arquivo,
                input_data.laboratorio,
                input_data.setor,
                input_data.categoria_item,
                input_data.tipo,
                input_data.codigo,
                input_data.item,
                input_data.unidade,
                input_data.quantidade,
                input_data.valor_unitario,
                valor_total,
                input_data.ano or 2027,
                id
            )
        )
        conn.commit()
        
        # Verifica se alguma linha foi afetada
        affected = cursor.rowcount
        conn.close()
        
        if affected == 0:
            raise HTTPException(status_code=404, detail="Item não encontrado.")
            
        return {"success": True, "message": "Item atualizado com sucesso!"}
    except Exception as e:
        conn.rollback()
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao atualizar item: {str(e)}")

@app.delete("/api/pca/{id}")
def deletar_item(id: int, x_user_role: Optional[str] = Header(None), x_username: Optional[str] = Header(None)):
    if x_user_role != "admin":
        check_global_lock()
        if x_username:
            check_user_lock(x_username)

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM pca.itens WHERE id = %s", (id,))
        conn.commit()
        affected = cursor.rowcount
        conn.close()
        
        if affected == 0:
            raise HTTPException(status_code=404, detail="Item não encontrado.")
            
        return {"success": True, "message": "Item excluído com sucesso!"}
    except Exception as e:
        conn.rollback()
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao excluir item: {str(e)}")

class LoginRequest(BaseModel):
    username: str
    password: str

@app.post("/api/pca/login")
def pca_login(req: LoginRequest):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, username, name, role, edit_locked FROM contratos.users WHERE username = %s AND password = %s", (req.username, req.password))
        user = cursor.fetchone()
        conn.close()
        if user:
            return dict(user)
        raise HTTPException(status_code=401, detail="Usuário ou senha incorretos")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro de Banco de Dados: {str(e)}")

# --- NOVOS MODELOS E ENDPOINTS PARA PARAMETROS E USUARIOS ---

class UserCreate(BaseModel):
    username: str
    password: str
    name: str
    role: str

class NameInput(BaseModel):
    nome: str

@app.get("/api/pca/users")
def list_users():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, username, name, role, edit_locked FROM contratos.users ORDER BY id DESC")
        users = [dict(r) for r in cursor.fetchall()]
        conn.close()
        return users
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao listar usuários: {str(e)}")

@app.post("/api/pca/users", status_code=201)
def create_user(u: UserCreate):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO contratos.users (username, password, name, role) VALUES (%s, %s, %s, %s) RETURNING id",
            (u.username, u.password, u.name, u.role)
        )
        new_id = cursor.fetchone()['id']
        
        # Cria automaticamente a categoria/laboratório correspondente ao nome do usuário
        if u.role != 'admin':
            cursor.execute("INSERT INTO pca.laboratorios (nome) VALUES (%s) ON CONFLICT DO NOTHING", (u.name,))
            
        conn.commit()
        conn.close()
        return {"id": new_id, "success": True, "message": "Usuário criado com sucesso!"}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao criar usuário: {str(e)}")

@app.delete("/api/pca/users/{id}")
def delete_user(id: int):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM contratos.users WHERE id = %s", (id,))
        conn.commit()
        affected = cursor.rowcount
        conn.close()
        if affected == 0:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
        return {"success": True, "message": "Usuário excluído com sucesso!"}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao excluir usuário: {str(e)}")

class UserUpdate(BaseModel):
    username: str
    name: str
    role: str
    edit_locked: Optional[bool] = False
    password: Optional[str] = None

@app.put("/api/pca/users/{id}")
def update_user(id: int, u: UserUpdate):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        if u.password and u.password.strip():
            cursor.execute(
                "UPDATE contratos.users SET username = %s, name = %s, role = %s, edit_locked = %s, password = %s WHERE id = %s",
                (u.username, u.name, u.role, u.edit_locked, u.password, id)
            )
        else:
            cursor.execute(
                "UPDATE contratos.users SET username = %s, name = %s, role = %s, edit_locked = %s WHERE id = %s",
                (u.username, u.name, u.role, u.edit_locked, id)
            )
        conn.commit()
        affected = cursor.rowcount
        conn.close()
        if affected == 0:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
        return {"success": True, "message": "Usuário atualizado com sucesso!"}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao atualizar usuário: {str(e)}")

@app.post("/api/pca/users/{id}/lock")
def lock_user_planning(id: int):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE contratos.users SET edit_locked = TRUE WHERE id = %s", (id,))
        conn.commit()
        affected = cursor.rowcount
        conn.close()
        if affected == 0:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
        return {"success": True, "message": "Planejamento finalizado com sucesso!"}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao finalizar planejamento: {str(e)}")

# --- PARAMETROS DINAMICOS: LABORATORIOS ---

@app.get("/api/pca/laboratorios")
def list_laboratorios():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, nome FROM pca.laboratorios ORDER BY nome ASC")
        labs = [dict(r) for r in cursor.fetchall()]
        conn.close()
        return labs
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao listar laboratórios: {str(e)}")

@app.post("/api/pca/laboratorios", status_code=201)
def create_laboratorio(item: NameInput):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO pca.laboratorios (nome) VALUES (%s) RETURNING id", (item.nome,))
        new_id = cursor.fetchone()['id']
        conn.commit()
        conn.close()
        return {"id": new_id, "success": True}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao criar laboratório: {str(e)}")

@app.delete("/api/pca/laboratorios/{id}")
def delete_laboratorio(id: int):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM pca.laboratorios WHERE id = %s", (id,))
        conn.commit()
        affected = cursor.rowcount
        conn.close()
        if affected == 0:
            raise HTTPException(status_code=404, detail="Laboratório não encontrado")
        return {"success": True}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao excluir laboratório: {str(e)}")

# --- PARAMETROS DINAMICOS: CATEGORIAS ---

@app.get("/api/pca/categorias")
def list_categorias():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, nome FROM pca.categorias ORDER BY nome ASC")
        cats = [dict(r) for r in cursor.fetchall()]
        conn.close()
        return cats
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao listar categorias: {str(e)}")

@app.post("/api/pca/categorias", status_code=201)
def create_categoria(item: NameInput):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO pca.categorias (nome) VALUES (%s) RETURNING id", (item.nome,))
        new_id = cursor.fetchone()['id']
        conn.commit()
        conn.close()
        return {"id": new_id, "success": True}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao criar categoria: {str(e)}")

@app.delete("/api/pca/categorias/{id}")
def delete_categoria(id: int):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM pca.categorias WHERE id = %s", (id,))
        conn.commit()
        affected = cursor.rowcount
        conn.close()
        if affected == 0:
            raise HTTPException(status_code=404, detail="Categoria não encontrada")
        return {"success": True}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao excluir categoria: {str(e)}")

# --- PARAMETROS DINAMICOS: TIPOS DE RECURSO ---

@app.get("/api/pca/tipos-recurso")
def list_tipos_recurso():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, nome FROM pca.tipos_recurso ORDER BY nome ASC")
        recursos = [dict(r) for r in cursor.fetchall()]
        conn.close()
        return recursos
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao listar tipos de recurso: {str(e)}")

@app.post("/api/pca/tipos-recurso", status_code=201)
def create_tipo_recurso(item: NameInput):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO pca.tipos_recurso (nome) VALUES (%s) RETURNING id", (item.nome,))
        new_id = cursor.fetchone()['id']
        conn.commit()
        conn.close()
        return {"id": new_id, "success": True}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao criar tipo de recurso: {str(e)}")

@app.delete("/api/pca/tipos-recurso/{id}")
def delete_tipo_recurso(id: int):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM pca.tipos_recurso WHERE id = %s", (id,))
        conn.commit()
        affected = cursor.rowcount
        conn.close()
        if affected == 0:
            raise HTTPException(status_code=404, detail="Tipo de recurso não encontrado")
        return {"success": True}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao excluir tipo de recurso: {str(e)}")

class CopiarAnoRequest(BaseModel):
    de_ano: int
    para_ano: int

@app.post("/api/pca/copiar-ano")
def copiar_ano(req: CopiarAnoRequest):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) as count FROM pca.itens WHERE ano = %s", (req.de_ano,))
        count = cursor.fetchone()['count']
        if count == 0:
            conn.close()
            raise HTTPException(status_code=400, detail=f"Não existem itens cadastrados no ano de {req.de_ano} para copiar.")
            
        cursor.execute("DELETE FROM pca.itens WHERE ano = %s", (req.para_ano,))
        
        cursor.execute(
            """
            INSERT INTO pca.itens 
            (origem_pasta, origem_arquivo, laboratorio, setor, categoria_item, tipo, codigo, item, unidade, quantidade, valor_unitario, valor_total, data_sincronizacao, ano)
            SELECT origem_pasta, origem_arquivo, laboratorio, setor, categoria_item, tipo, codigo, item, unidade, quantidade, valor_unitario, valor_total, NOW(), %s
            FROM pca.itens
            WHERE ano = %s
            """,
            (req.para_ano, req.de_ano)
        )
        copied_count = cursor.rowcount
        conn.commit()
        conn.close()
        
        return {
            "success": True,
            "message": f"Sucesso! {copied_count} itens copiados de {req.de_ano} para {req.para_ano}."
        }
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Erro ao copiar itens de ano: {str(e)}")

class ConfigInput(BaseModel):
    liberacao_fim: Optional[str] = None # ISO format timestamp or None

@app.get("/api/pca/config")
def get_global_config():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT liberacao_fim FROM pca.configuracoes WHERE id = 1")
        row = cursor.fetchone()
        if row:
            lib_fim = row['liberacao_fim']
            is_active = False
            if lib_fim is not None:
                is_active = datetime.now() < lib_fim
            return {
                "liberacao_fim": lib_fim.isoformat() if lib_fim else None,
                "is_globally_released": is_active
            }
        return {"liberacao_fim": None, "is_globally_released": False}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao obter configuração: {str(e)}")
    finally:
        conn.close()

@app.post("/api/pca/config")
def update_global_config(cfg: ConfigInput):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        val = None
        if cfg.liberacao_fim:
            try:
                val = datetime.fromisoformat(cfg.liberacao_fim.replace('Z', ''))
            except Exception:
                raise HTTPException(status_code=400, detail="Formato de data inválido. Use ISO 8601 (YYYY-MM-DDTHH:MM:SS)")
        
        cursor.execute("UPDATE pca.configuracoes SET liberacao_fim = %s WHERE id = 1", (val,))
        conn.commit()
        return {"success": True, "message": "Configuração atualizada com sucesso!"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao atualizar configuração: {str(e)}")
    finally:
        conn.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
