-- SCRIPT FINAL DE ALINHAMENTO COMPLETO - KM$ App
-- Execute este SQL no Supabase Dashboard para corrigir TODOS os schemas

-- 1. DROPAR tabelas se existirem para recriar limpas
DROP TABLE IF EXISTS trabalho CASCADE;
DROP TABLE IF EXISTS trabalhos CASCADE;
DROP TABLE IF EXISTS gastos CASCADE;
DROP TABLE IF EXISTS manutencoes CASCADE;
DROP TABLE IF EXISTS manutencao CASCADE;

-- 2. TABELA TRABALHO (SINGULAR) - Alinhada com Backend e Frontend
CREATE TABLE trabalho (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  ganhos DECIMAL(10,2) NOT NULL,
  km DECIMAL(8,2) NOT NULL,  -- ALINHADO: Backend/Frontend usa 'km'
  horas DECIMAL(4,2) NOT NULL,  -- ALINHADO: Backend/Frontend usa 'horas'
  observacoes TEXT,
  data_registro TIMESTAMP DEFAULT NOW(),  -- ALINHADO: Backend/Frontend usa 'data_registro'
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. TABELA GASTOS - Alinhada com Backend e Frontend
CREATE TABLE gastos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  categoria VARCHAR(50) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  descricao TEXT,
  data_registro TIMESTAMP DEFAULT NOW(),  -- ALINHADO: Backend/Frontend usa 'data_registro'
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. TABELA MANUTENCAO - Alinhada com Backend e Frontend  
CREATE TABLE manutencao (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  tipo VARCHAR(50) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  km_atual DECIMAL(8,2) NOT NULL,  -- ALINHADO: Backend/Frontend usa 'km_atual'
  descricao TEXT,
  data_registro TIMESTAMP DEFAULT NOW(),  -- ALINHADO: Backend/Frontend usa 'data_registro'
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. CRIAR ÍNDICES PARA PERFORMANCE
CREATE INDEX idx_trabalho_user_id ON trabalho(user_id);
CREATE INDEX idx_trabalho_data ON trabalho(data);
CREATE INDEX idx_trabalho_user_data ON trabalho(user_id, data);

CREATE INDEX idx_gastos_user_id ON gastos(user_id);
CREATE INDEX idx_gastos_data ON gastos(data);
CREATE INDEX idx_gastos_categoria ON gastos(categoria);
CREATE INDEX idx_gastos_user_data ON gastos(user_id, data);

CREATE INDEX idx_manutencao_user_id ON manutencao(user_id);
CREATE INDEX idx_manutencao_data ON manutencao(data);
CREATE INDEX idx_manutencao_tipo ON manutencao(tipo);
CREATE INDEX idx_manutencao_user_data ON manutencao(user_id, data);

-- 6. HABILITAR ROW LEVEL SECURITY (RLS)
ALTER TABLE trabalho ENABLE ROW LEVEL SECURITY;
ALTER TABLE gastos ENABLE ROW LEVEL SECURITY;
ALTER TABLE manutencao ENABLE ROW LEVEL SECURITY;

-- 7. POLÍTICAS RLS PARA TRABALHO
CREATE POLICY "Users can view own trabalho" ON trabalho
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own trabalho" ON trabalho
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own trabalho" ON trabalho
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own trabalho" ON trabalho
    FOR DELETE USING (auth.uid() = user_id);

-- 8. POLÍTICAS RLS PARA GASTOS
CREATE POLICY "Users can view own gastos" ON gastos
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own gastos" ON gastos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own gastos" ON gastos
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own gastos" ON gastos
    FOR DELETE USING (auth.uid() = user_id);

-- 9. POLÍTICAS RLS PARA MANUTENCAO
CREATE POLICY "Users can view own manutencao" ON manutencao
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own manutencao" ON manutencao
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own manutencao" ON manutencao
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own manutencao" ON manutencao
    FOR DELETE USING (auth.uid() = user_id);

-- 10. TRIGGERS PARA UPDATED_AT AUTOMÁTICO
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_trabalho_updated_at BEFORE UPDATE ON trabalho
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gastos_updated_at BEFORE UPDATE ON gastos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_manutencao_updated_at BEFORE UPDATE ON manutencao
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 11. VERIFICAÇÃO FINAL
SELECT 
    tablename,
    schemaname
FROM pg_tables 
WHERE tablename IN ('trabalho', 'gastos', 'manutencao')
AND schemaname = 'public'
ORDER BY tablename;

-- 12. VERIFICAR COLUNAS DAS TABELAS
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('trabalho', 'gastos', 'manutencao')
AND table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- ✅ SCHEMA AGORA 100% ALINHADO ENTRE:
-- ✅ Backend Models (Dart)
-- ✅ Frontend Models (Flutter)
-- ✅ Supabase Database (PostgreSQL)