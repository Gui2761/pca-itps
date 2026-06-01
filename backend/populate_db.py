import os
import re
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
import openpyxl
import pandas as pd
from datetime import datetime
import psycopg2
import psycopg2.extras

# --- CONFIGURAÇÕES DO BANCO DE DADOS POSTGRES ---
PG_HOST = "172.23.6.109"
PG_PORT = 5432
PG_USER = "geinform"
PG_PASSWORD = "intr@bd109"
PG_DB = "bd_intranet"

def get_db_connection():
    return psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        user=PG_USER,
        password=PG_PASSWORD,
        database=PG_DB,
        cursor_factory=psycopg2.extras.RealDictCursor
    )

def clean_float_pca(val):
    if val is None or pd.isna(val):
        return 0.0
    if isinstance(val, (int, float)):
        return float(val)
    val_str = str(val).strip().replace('R$', '').replace('r$', '').replace(' ', '')
    if ',' in val_str and '.' in val_str:
        val_str = val_str.replace('.', '').replace(',', '.')
    elif ',' in val_str:
        val_str = val_str.replace(',', '.')
    match = re.search(r'[-+]?\d*\.\d+|\d+', val_str)
    if match:
        try:
            return float(match.group(0))
        except:
            pass
    return 0.0

def parse_sheet_pca(file_path, sheet_name):
    df = pd.read_excel(file_path, sheet_name=sheet_name, header=None)
    header_idx = None
    for i in range(min(10, len(df))):
        row_vals = [str(val).upper().strip() for val in df.iloc[i].values if val is not None]
        if any("ITEM" in r or "TIPO" in r or "CÓDIGO" in r for r in row_vals):
            header_idx = i
            break
            
    if header_idx is None:
        header_idx = 0
        
    df.columns = [str(c).strip() for c in df.iloc[header_idx].values]
    df = df.iloc[header_idx + 1:].copy()
    normalized_cols = {str(c).upper().strip(): c for c in df.columns}
    
    col_tipo = None
    col_codigo = None
    col_item = None
    col_unidade = None
    col_qtde = None
    col_val_unit = None
    col_val_total = None
    
    for up_col, orig_col in normalized_cols.items():
        if "TIPO" in up_col:
            col_tipo = orig_col
        elif "CÓDIGO" in up_col or "CODIGO" in up_col or "CÓD. i-GESP" in up_col or "COD. I-GESP" in up_col:
            col_codigo = orig_col
        elif "ITEM" in up_col or "DESCRIÇÃO" in up_col or "DESCRICAO" in up_col:
            col_item = orig_col
        elif "UNIDADE" in up_col or "UNID" in up_col:
            col_unidade = orig_col
        elif "QTDE" in up_col or "QUANTIDADE" in up_col or "QUANT" in up_col or "QTD" in up_col:
            col_qtde = orig_col
        elif "VALOR_UNIT" in up_col or "VALOR UNIT" in up_col or "UNITÁRIO" in up_col or "UNITARIO" in up_col or "VALOR_UNITARIO" in up_col:
            col_val_unit = orig_col
        elif "VALOR_TOTAL" in up_col or "VALOR TOTAL" in up_col or "TOTAL" in up_col:
            col_val_total = orig_col

    if not col_item:
        if len(df.columns) > 2:
            col_item = df.columns[2]
        else:
            col_item = df.columns[0]
            
    parsed_rows = []
    for _, row in df.iterrows():
        item_val = row.get(col_item)
        if pd.isna(item_val) or str(item_val).strip() == "" or str(item_val).strip().upper() == "ITEM":
            continue
            
        tipo = str(row.get(col_tipo, "")).strip() if col_tipo and not pd.isna(row.get(col_tipo)) else ""
        codigo = str(row.get(col_codigo, "")).strip() if col_codigo and not pd.isna(row.get(col_codigo)) else ""
        item = str(item_val).strip()
        unidade = str(row.get(col_unidade, "")).strip() if col_unidade and not pd.isna(row.get(col_unidade)) else ""
        
        qtde = clean_float_pca(row.get(col_qtde)) if col_qtde else 0.0
        val_unit = clean_float_pca(row.get(col_val_unit)) if col_val_unit else 0.0
        val_total = clean_float_pca(row.get(col_val_total)) if col_val_total else (qtde * val_unit)
        
        if "TOTAL" in item.upper() or "SOMA" in item.upper():
            continue
            
        parsed_rows.append({
            "tipo": tipo,
            "codigo": codigo,
            "item": item,
            "unidade": unidade,
            "quantidade": qtde,
            "valor_unitario": val_unit,
            "valor_total": val_total
        })
        
    return parsed_rows

def map_lab_name(filename):
    f_upper = filename.upper()
    if "AGUAS" in f_upper or "ÁGUA" in f_upper:
        return "Química de Águas"
    elif "INORG" in f_upper:
        return "Inorgânica"
    elif "MICRO" in f_upper:
        return "Microbiologia"
    elif "SOLOS" in f_upper:
        return "Solos"
    elif "BROMAT" in f_upper:
        return "Bromatologia"
    elif "ORG" in f_upper:
        return "Orgânica"
    elif "AGEQUALI" in f_upper:
        return "Qualidade"
    elif "GECONF" in f_upper:
        return "Geconf"
    return "GEAAD / Insumos Gerais"

def map_category_item(sheet_name):
    s_upper = sheet_name.upper()
    if "EQUIP" in s_upper:
        return "Equipamento"
    elif any(k in s_upper for k in ["SERVI", "SERV", "CALIBR", "MANUTEN", "PEP", "TREIN"]):
        return "Serviço"
    return "Material de Consumo"

def populate_database():
    paths_config = [
        {"pasta": "Laboratórios", "caminho": r"\\172.23.6.7\ageplan\ANO 2026\PCA - 2027\Laboratórios"},
        {"pasta": "PCA", "caminho": r"\\172.23.6.7\ageplan\ANO 2026\PCA - 2027\PCA"},
        {"pasta": "GEAAD", "caminho": r"\\172.23.6.7\ageplan\ANO 2026\PCA - 2027\PCA\GEAAD"}
    ]
    
    print("Conectando ao banco PostgreSQL central...")
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        print("Limpando dados existentes em pca.itens...")
        cursor.execute("TRUNCATE TABLE pca.itens RESTART IDENTITY CASCADE;")
        conn.commit()
        
        total_importado = 0
        
        for config in paths_config:
            caminho = config["caminho"]
            pasta_nome = config["pasta"]
            
            if not os.path.exists(caminho):
                print(f"  [AVISO] Caminho não encontrado: {caminho}")
                continue
                
            print(f"Lendo planilhas de: {pasta_nome}...")
            for file in os.listdir(caminho):
                if file.endswith(".xlsx") and not file.startswith("~$"):
                    full_path = os.path.join(caminho, file)
                    print(f"  File: {file}")
                    
                    try:
                        wb = openpyxl.load_workbook(full_path, read_only=True)
                        sheets = wb.sheetnames
                        wb.close()
                        
                        lab = map_lab_name(file)
                        
                        for sheet in sheets:
                            cat = map_category_item(sheet)
                            dados_linhas = parse_sheet_pca(full_path, sheet)
                            
                            if dados_linhas:
                                for row in dados_linhas:
                                    setor = row["tipo"] if row["tipo"] else sheet
                                    
                                    try:
                                        cursor.execute(
                                            """
                                            INSERT INTO pca.itens 
                                            (origem_pasta, origem_arquivo, laboratorio, setor, categoria_item, tipo, codigo, item, unidade, quantidade, valor_unitario, valor_total, data_sincronizacao)
                                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                                            """,
                                            (
                                                pasta_nome,
                                                file,
                                                lab,
                                                setor,
                                                cat,
                                                row["tipo"],
                                                row["codigo"],
                                                row["item"],
                                                row["unidade"],
                                                row["quantidade"],
                                                row["valor_unitario"],
                                                row["valor_total"],
                                                datetime.now()
                                            )
                                        )
                                        total_importado += 1
                                    except Exception as insert_error:
                                        print(f"      [AVISO] Falha ao inserir linha: {insert_error}")
                                        conn.rollback()
                                        
                        # Commit por arquivo para garantir persistência incremental
                        conn.commit()
                        
                    except Exception as e:
                        print(f"    Error on file {file}: {e}")
                        conn.rollback()
                        
        print(f"\nPOPULATION COMPLETED! Total of {total_importado} items imported.")
    except Exception as e:
        print(f"Error on populating: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    populate_database()
