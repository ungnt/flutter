-- Script para corrigir tabelas no Supabase para compatibilidade com KM$ App
-- Execute este SQL no dashboard do Supabase (SQL Editor)

-- 1. DROPAR tabelas antigas se existirem (cuidado com dados!)
DROP TABLE IF EXISTS trabalho CASCADE;
DROP TABLE IF EXISTS manutencoes CASCADE;

-- 2. Criar tabela TRABALHOS (plural) com campos corretos
CREATE TABLE IF NOT EXISTS trabalhos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  ganhos DECIMAL(10,2) NOT NULL,
  km DECIMAL(8,2) NOT NULL,  -- Mudou de quilometragem_inicial/final para km
  horas DECIMAL(4,2) NOT NULL,  -- Mudou de horas_trabalhadas para horas
  observacoes TEXT,
  data_registro TIMESTAMP DEFAULT NOW(),  -- Mudou de created_at para data_registro
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. Verificar se tabela gastos existe com campos corretos
CREATE TABLE IF NOT EXISTS gastos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  categoria VARCHAR(50) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  descricao TEXT,
  data_registro TIMESTAMP DEFAULT NOW(),  -- Mudou de created_at para data_registro
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. Criar tabela manutencoes (se necessário)
CREATE TABLE IF NOT EXISTS manutencoes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  tipo VARCHAR(50) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  quilometragem INTEGER NOT NULL,
  descricao TEXT,
  oficina VARCHAR(100),
  data_registro TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_trabalhos_user_id ON trabalhos(user_id);
CREATE INDEX IF NOT EXISTS idx_trabalhos_data ON trabalhos(data);
CREATE INDEX IF NOT EXISTS idx_trabalhos_user_data ON trabalhos(user_id, data);

CREATE INDEX IF NOT EXISTS idx_gastos_user_id ON gastos(user_id);
CREATE INDEX IF NOT EXISTS idx_gastos_data ON gastos(data);
CREATE INDEX IF NOT EXISTS idx_gastos_categoria ON gastos(categoria);
CREATE INDEX IF NOT EXISTS idx_gastos_user_data ON gastos(user_id, data);

CREATE INDEX IF NOT EXISTS idx_manutencoes_user_id ON manutencoes(user_id);
CREATE INDEX IF NOT EXISTS idx_manutencoes_data ON manutencoes(data);
CREATE INDEX IF NOT EXISTS idx_manutencoes_tipo ON manutencoes(tipo);

-- 6. Habilitar Row Level Security (RLS)
ALTER TABLE trabalhos ENABLE ROW LEVEL SECURITY;
ALTER TABLE gastos ENABLE ROW LEVEL SECURITY;
ALTER TABLE manutencoes ENABLE ROW LEVEL SECURITY;

-- 7. Criar políticas RLS para trabalhos
CREATE POLICY "Users can view own trabalhos" ON trabalhos
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own trabalhos" ON trabalhos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own trabalhos" ON trabalhos
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own trabalhos" ON trabalhos
    FOR DELETE USING (auth.uid() = user_id);

-- 8. Criar políticas RLS para gastos
CREATE POLICY "Users can view own gastos" ON gastos
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own gastos" ON gastos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own gastos" ON gastos
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own gastos" ON gastos
    FOR DELETE USING (auth.uid() = user_id);

-- 9. Criar políticas RLS para manutencoes
CREATE POLICY "Users can view own manutencoes" ON manutencoes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own manutencoes" ON manutencoes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own manutencoes" ON manutencoes
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own manutencoes" ON manutencoes
    FOR DELETE USING (auth.uid() = user_id);

-- 10. Verificar se as tabelas foram criadas corretamente
SELECT 
    tablename,
    schemaname
FROM pg_tables 
WHERE tablename IN ('trabalhos', 'gastos', 'manutencoes')
AND schemaname = 'public'
ORDER BY tablename;

-- 11. Verificar colunas das tabelas
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('trabalhos', 'gastos', 'manutencoes')
AND table_schema = 'public'
ORDER BY table_name, ordinal_position;